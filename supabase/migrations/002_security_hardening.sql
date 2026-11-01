-- StudyLock 002 — security hardening, AI usage limits, role requests, attendance roster.
-- Safe to re-run (idempotent). Run in the Supabase SQL editor AFTER 001_full_schema.sql.
-- Works with schemas where user_roles.role / has_role() / my_role() use TEXT.

-- ── 0. Pre-flight: abort with a clear message (and change nothing) if the schema differs ──
do $$
declare
  req text[][] := array[
    ['user_roles','user_id'],['user_roles','role'],
    ['profiles','id'],['profiles','email'],['profiles','full_name'],
    ['quizzes','id'],['quizzes','questions'],
    ['quiz_attempts','quiz_id'],['quiz_attempts','answers'],['quiz_attempts','score'],['quiz_attempts','total_marks'],
    ['assignments','id'],['assignments','deadline'],
    ['submissions','assignment_id'],['submissions','marks_obtained'],['submissions','feedback'],
    ['submissions','graded_by'],['submissions','graded_at'],['submissions','submitted_at'],['submissions','status'],
    ['login_events','user_id'],['login_events','email'],['login_events','name'],['login_events','role'],
    ['attendance','course_id'],['attendance','student_id'],
    ['enrollments','course_id'],['enrollments','student_id'],
    ['courses','id'],['courses','lecturer_id'],
    ['notifications','user_id'],
    ['lectures','id'],['lectures','views'],
    ['game_state','points'],['game_state','streak'],['game_state','longest_streak'],
    ['study_sessions','elapsed_seconds'],['study_sessions','violations'],['study_sessions','planned_duration_seconds']
  ];
  missing text := '';
  i int;
begin
  for i in 1 .. array_length(req, 1) loop
    if not exists (select 1 from information_schema.columns
                    where table_schema = 'public' and table_name = req[i][1] and column_name = req[i][2]) then
      missing := missing || req[i][1] || '.' || req[i][2] || ', ';
    end if;
  end loop;
  if not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name='quizzes' and column_name='questions' and data_type='jsonb') then
    missing := missing || 'quizzes.questions(jsonb), ';
  end if;
  if missing <> '' then
    raise exception 'Schema mismatch - missing: %', missing;
  end if;
end $$;

-- ── 1. Harden SECURITY DEFINER functions (fixed search_path, no anon access) ──
create or replace function public.has_role(uid uuid, r text)
returns boolean language sql security definer stable set search_path = public as $$
  select exists(select 1 from public.user_roles where user_id = uid and role = r);
$$;

create or replace function public.my_role()
returns text language sql security definer stable set search_path = public as $$
  select role from public.user_roles where user_id = auth.uid() limit 1;
$$;

create or replace function public.increment_lecture_views(lecture_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.lectures set views = views + 1 where id = lecture_id;
$$;

revoke execute on function public.has_role(uuid, text) from public, anon;
revoke execute on function public.my_role() from public, anon;
revoke execute on function public.increment_lecture_views(uuid) from public, anon;
grant execute on function public.has_role(uuid, text) to authenticated, service_role;
grant execute on function public.my_role() to authenticated, service_role;
grant execute on function public.increment_lecture_views(uuid) to authenticated, service_role;

-- ── 2. AI usage log (used by the ai-proxy Edge Function for rate limiting) ──
create table if not exists public.ai_usage (
  id         bigserial primary key,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  task       text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_ai_usage_user_time on public.ai_usage(user_id, created_at desc);
alter table public.ai_usage enable row level security;  -- no policies: service role only

-- ── 3. Lecturer role requests (clients can never grant themselves a role) ──
create table if not exists public.role_requests (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles(id) on delete cascade deferrable initially deferred,
  requested_role text not null check (requested_role = 'lecturer'),
  status         text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at     timestamptz not null default now(),
  unique(user_id)
);
alter table public.role_requests enable row level security;
drop policy if exists "rolereq_select" on public.role_requests;
create policy "rolereq_select" on public.role_requests for select
  using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
drop policy if exists "rolereq_admin" on public.role_requests;
create policy "rolereq_admin" on public.role_requests for update
  using (public.has_role(auth.uid(), 'admin'));

-- Lecturer signups only create a PENDING request. We add a separate trigger so your
-- existing handle_new_user() (profile, role, game_state) is left untouched.
create or replace function public.create_role_request_on_signup()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.raw_user_meta_data->>'requested_role' = 'lecturer' then
    insert into public.role_requests(user_id, requested_role) values(new.id, 'lecturer')
    on conflict (user_id) do nothing;
  end if;
  return new;
end;$$;
drop trigger if exists z_role_request_on_signup on auth.users;
create trigger z_role_request_on_signup after insert on auth.users
  for each row execute procedure public.create_role_request_on_signup();

-- When an admin sets the requested role, mark the request approved.
create or replace function public.sync_role_request()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.role_requests set status = 'approved'
   where user_id = new.user_id and requested_role = new.role and status = 'pending';
  return new;
end;$$;
drop trigger if exists on_user_role_changed on public.user_roles;
create trigger on_user_role_changed after update of role on public.user_roles
  for each row execute procedure public.sync_role_request();

-- ── 4. Server-side quiz scoring (students cannot choose their own score) ──
create or replace function public.enforce_quiz_attempt_score()
returns trigger language plpgsql security definer set search_path = public as $$
declare q jsonb; s int; t int;
begin
  select questions into q from public.quizzes where id = new.quiz_id;
  if q is null then raise exception 'Quiz not found'; end if;
  select coalesce(sum(coalesce((e->>'marks')::int, 1)), 0),
         coalesce(sum(case when new.answers->>(e->>'id') = e->>'correctAnswer'
                           then coalesce((e->>'marks')::int, 1) else 0 end), 0)
    into t, s
    from jsonb_array_elements(q) e;
  new.total_marks := t;
  new.score := s;
  return new;
end;$$;
drop trigger if exists quiz_attempt_score on public.quiz_attempts;
create trigger quiz_attempt_score before insert on public.quiz_attempts
  for each row execute procedure public.enforce_quiz_attempt_score();

-- ── 5. Submissions: students cannot self-grade or fake timestamps ──
create or replace function public.enforce_submission_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
declare d timestamptz;
begin
  select deadline into d from public.assignments where id = new.assignment_id;
  new.marks_obtained := null;
  new.feedback := null;
  new.graded_by := null;
  new.graded_at := null;
  new.submitted_at := now();
  new.status := case when d is not null and now() > d then 'late' else 'submitted' end;
  return new;
end;$$;
drop trigger if exists submission_defaults on public.submissions;
create trigger submission_defaults before insert on public.submissions
  for each row execute procedure public.enforce_submission_defaults();

-- ── 6. Login events: identity fields come from the server, not the client ──
create or replace function public.enforce_login_event()
returns trigger language plpgsql security definer set search_path = public as $$
declare p record;
begin
  select email, full_name into p from public.profiles where id = new.user_id;
  new.email := coalesce(p.email, new.email);
  new.name  := coalesce(p.full_name, new.name);
  new.role  := coalesce((select role::text from public.user_roles where user_id = new.user_id), 'student');
  return new;
end;$$;
drop trigger if exists login_event_identity on public.login_events;
create trigger login_event_identity before insert on public.login_events
  for each row execute procedure public.enforce_login_event();

-- ── 7. Attendance: only the course's lecturer (or admin) may write; idempotent ──
drop policy if exists "Students view own attendance" on public.attendance;
drop policy if exists "Lecturers manage attendance" on public.attendance;
drop policy if exists "attendance_select" on public.attendance;
drop policy if exists "attendance_write" on public.attendance;

create policy "attendance_select" on public.attendance for select
  using (
    student_id = auth.uid()
    or public.has_role(auth.uid(), 'admin')
    or exists (select 1 from public.courses c where c.id = course_id and c.lecturer_id = auth.uid())
  );

create policy "attendance_write" on public.attendance for all
  using (
    public.has_role(auth.uid(), 'admin')
    or exists (select 1 from public.courses c where c.id = course_id and c.lecturer_id = auth.uid())
  )
  with check (
    public.has_role(auth.uid(), 'admin')
    or (
      exists (select 1 from public.courses c where c.id = course_id and c.lecturer_id = auth.uid())
      and exists (select 1 from public.enrollments e where e.course_id = attendance.course_id and e.student_id = attendance.student_id)
    )
  );

-- Roster of enrolled students for a course (lecturers cannot read other profiles directly).
create or replace function public.get_course_roster(p_course_id uuid)
returns table(student_id uuid, full_name text)
language plpgsql security definer stable set search_path = public as $$
begin
  if not (
    public.has_role(auth.uid(), 'admin')
    or exists (select 1 from public.courses c where c.id = p_course_id and c.lecturer_id = auth.uid())
  ) then
    raise exception 'Not allowed';
  end if;
  return query
    select e.student_id, p.full_name
      from public.enrollments e join public.profiles p on p.id = e.student_id
     where e.course_id = p_course_id
     order by p.full_name;
end;$$;
revoke execute on function public.get_course_roster(uuid) from public, anon;
grant execute on function public.get_course_roster(uuid) to authenticated;

-- ── 8. Notifications: lecturers may only notify students enrolled in their courses ──
drop policy if exists "notif_insert" on public.notifications;
create policy "notif_insert" on public.notifications for insert
  with check (
    user_id = auth.uid()
    or public.has_role(auth.uid(), 'admin')
    or (
      public.has_role(auth.uid(), 'lecturer')
      and exists (
        select 1 from public.enrollments e join public.courses c on c.id = e.course_id
         where e.student_id = notifications.user_id and c.lecturer_id = auth.uid()
      )
    )
  );

-- ── 9. Avatars: owners can replace / delete their own file ──
drop policy if exists "avatars_update" on storage.objects;
create policy "avatars_update" on storage.objects for update
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
drop policy if exists "avatars_delete" on storage.objects;
create policy "avatars_delete" on storage.objects for delete
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

-- ── 10. Basic data sanity constraints (NOT VALID = don't fail on legacy rows) ──
do $$ begin
  alter table public.game_state add constraint game_state_nonneg check (points >= 0 and streak >= 0 and longest_streak >= 0) not valid;
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.study_sessions add constraint study_sessions_sane check (elapsed_seconds >= 0 and violations >= 0 and planned_duration_seconds > 0) not valid;
exception when duplicate_object then null; end $$;
