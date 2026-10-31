-- StudyLock 003 — remove over-permissive legacy policies and replace them with scoped ones.
-- Run AFTER 002. Idempotent. Pre-flight aborts (changing nothing) if the schema differs.
--
-- Why: Postgres ORs permissive policies, so "USING (true)" policies cancel every stricter
-- policy on the same table.

-- ── 0. Pre-flight ──
do $$
declare
  req text[][] := array[
    ['assignments','id'],['assignments','course_id'],['assignments','created_by'],['assignments','deadline'],
    ['quizzes','id'],['quizzes','course_id'],['quizzes','created_by'],
    ['courses','id'],['courses','lecturer_id'],
    ['submissions','assignment_id'],['submissions','student_id'],['submissions','status'],
    ['submissions','marks_obtained'],['submissions','feedback'],['submissions','graded_by'],
    ['submissions','graded_at'],['submissions','submitted_at'],
    ['quiz_attempts','quiz_id'],['quiz_attempts','student_id'],['quiz_attempts','score'],['quiz_attempts','total_marks'],
    ['attendance','student_id'],['attendance','status'],
    ['profiles','email'],['profiles','full_name'],['profiles','department'],
    ['game_state','user_id'],['game_state','points'],['game_state','streak'],
    ['study_sessions','user_id'],['study_sessions','valid_session'],['study_sessions','elapsed_seconds']
  ];
  missing text := '';
  i int;
begin
  for i in 1 .. array_length(req, 1) loop
    if not exists (select 1 from information_schema.columns
                    where table_schema='public' and table_name=req[i][1] and column_name=req[i][2]) then
      missing := missing || req[i][1] || '.' || req[i][2] || ', ';
    end if;
  end loop;
  if missing <> '' then
    raise exception 'Schema mismatch - missing: %', missing;
  end if;
end $$;

-- ── 1. Helper functions (SECURITY DEFINER avoids RLS recursion) ──
create or replace function public.can_manage_assignment(a_id uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select public.has_role(auth.uid(), 'admin') or exists (
    select 1 from public.assignments a
    left join public.courses c on c.id = a.course_id
    where a.id = a_id and (a.created_by = auth.uid() or c.lecturer_id = auth.uid())
  );
$$;

create or replace function public.can_manage_quiz(q_id uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select public.has_role(auth.uid(), 'admin') or exists (
    select 1 from public.quizzes q
    left join public.courses c on c.id = q.course_id
    where q.id = q_id and (q.created_by = auth.uid() or c.lecturer_id = auth.uid())
  );
$$;

revoke execute on function public.can_manage_assignment(uuid) from public, anon;
revoke execute on function public.can_manage_quiz(uuid) from public, anon;
grant execute on function public.can_manage_assignment(uuid) to authenticated, service_role;
grant execute on function public.can_manage_quiz(uuid) to authenticated, service_role;

-- ── 2. Drop the over-permissive legacy policies ──
drop policy if exists "All can read attendance" on public.attendance;
drop policy if exists "Lecturer can insert attendance" on public.attendance;
drop policy if exists "Lecturer can update attendance" on public.attendance;
drop policy if exists "Authenticated can insert notifications" on public.notifications;
drop policy if exists "All read attempts" on public.quiz_attempts;
drop policy if exists "All read submissions" on public.submissions;
drop policy if exists "Lecturer update submissions" on public.submissions;

-- ── 3. Quiz attempts: own attempts, or the quiz's lecturer / admin ──
drop policy if exists "attempts_select" on public.quiz_attempts;
create policy "attempts_select" on public.quiz_attempts for select
  using (student_id = auth.uid() or public.can_manage_quiz(quiz_id));

-- ── 4. Submissions ──
drop policy if exists "subs_select" on public.submissions;
create policy "subs_select" on public.submissions for select
  using (student_id = auth.uid() or public.can_manage_assignment(assignment_id));

drop policy if exists "subs_staff_update" on public.submissions;
create policy "subs_staff_update" on public.submissions for update
  using (public.can_manage_assignment(assignment_id))
  with check (public.can_manage_assignment(assignment_id));

-- Students may re-submit (the app uses upsert) until a submission is graded.
drop policy if exists "subs_student_update" on public.submissions;
create policy "subs_student_update" on public.submissions for update
  using (student_id = auth.uid() and status <> 'graded')
  with check (student_id = auth.uid());

-- Students can never alter grading fields, even on re-submit.
create or replace function public.protect_submission_grading()
returns trigger language plpgsql security definer set search_path = public as $$
declare d timestamptz;
begin
  if auth.uid() is null or public.can_manage_assignment(new.assignment_id) then
    return new;  -- SQL editor / service role / the assignment's lecturer or admin
  end if;
  select deadline into d from public.assignments where id = new.assignment_id;
  new.student_id     := old.student_id;
  new.assignment_id  := old.assignment_id;
  new.marks_obtained := old.marks_obtained;
  new.feedback       := old.feedback;
  new.graded_by      := old.graded_by;
  new.graded_at      := old.graded_at;
  new.submitted_at   := now();
  new.status         := case when d is not null and now() > d then 'late' else 'submitted' end;
  return new;
end;$$;
drop trigger if exists submission_protect_grading on public.submissions;
create trigger submission_protect_grading before update on public.submissions
  for each row execute procedure public.protect_submission_grading();

-- ── 5. Parent portal: aggregates only, instead of exposing raw student rows ──
create or replace function public.parent_child_summary(child_email text)
returns jsonb language plpgsql security definer stable set search_path = public as $$
declare
  p record; g record;
  att_total int; att_ok int; q_avg numeric; s_cnt int; s_min numeric;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;

  select id, full_name, department into p
    from public.profiles where lower(email) = lower(trim(child_email)) limit 1;
  if p.id is null then return null; end if;

  select points, streak into g from public.game_state where user_id = p.id;

  select count(*), count(*) filter (where status in ('present','late'))
    into att_total, att_ok from public.attendance where student_id = p.id;

  select coalesce(avg(case when total_marks > 0 then score::numeric / total_marks * 100 else 0 end), 0)
    into q_avg from public.quiz_attempts where student_id = p.id;

  select count(*), coalesce(sum(elapsed_seconds) / 60, 0)
    into s_cnt, s_min from public.study_sessions where user_id = p.id and valid_session = true;

  return jsonb_build_object(
    'name', coalesce(p.full_name, ''),
    'department', coalesce(p.department, ''),
    'points', coalesce(g.points, 0),
    'streak', coalesce(g.streak, 0),
    'attendance_pct', case when att_total = 0 then 0 else round(att_ok::numeric / att_total * 100, 1) end,
    'avg_quiz_score', round(q_avg, 1),
    'total_sessions', s_cnt,
    'study_minutes', floor(s_min)
  );
end;$$;
revoke execute on function public.parent_child_summary(text) from public, anon;
grant execute on function public.parent_child_summary(text) to authenticated;
