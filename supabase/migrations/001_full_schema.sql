-- StudyLock Full Production Schema
-- Run entirely in Supabase SQL Editor

create extension if not exists "uuid-ossp";

-- ── Enums ──────────────────────────────────────────────────────
do $$ begin
  create type user_role as enum ('student','lecturer','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type session_status as enum ('active','completed','failed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type submission_status as enum ('submitted','late','graded');
exception when duplicate_object then null; end $$;

-- ── Tables ─────────────────────────────────────────────────────
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null,
  full_name    text not null default '',
  avatar_url   text,
  department   text,
  registration_no text,
  designation  text,
  created_at   timestamptz default now() not null,
  updated_at   timestamptz default now() not null
);

create table if not exists public.user_roles (
  id      uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role    user_role not null default 'student',
  unique(user_id)
);

create or replace function public.has_role(uid uuid, r user_role)
returns boolean language sql security definer stable as $$
  select exists(select 1 from public.user_roles where user_id=uid and role=r);
$$;

create or replace function public.my_role()
returns user_role language sql security definer stable as $$
  select role from public.user_roles where user_id=auth.uid() limit 1;
$$;

create table if not exists public.login_events (
  id           bigserial primary key,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  role         text not null,
  email        text not null,
  name         text not null,
  device_info  text,
  logged_in_at timestamptz default now() not null
);

create table if not exists public.courses (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  description   text not null default '',
  subject       text not null default '',
  lecturer_id   uuid references public.profiles(id) on delete set null,
  lecturer_name text not null default '',
  created_at    timestamptz default now() not null
);

create table if not exists public.enrollments (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.profiles(id) on delete cascade,
  course_id   uuid not null references public.courses(id) on delete cascade,
  enrolled_at timestamptz default now() not null,
  unique(student_id, course_id)
);

create table if not exists public.lectures (
  id          uuid primary key default gen_random_uuid(),
  course_id   uuid references public.courses(id) on delete cascade,
  title       text not null,
  subject     text not null default '',
  description text not null default '',
  file_url    text not null default '',
  file_name   text not null default '',
  uploaded_by uuid not null references public.profiles(id) on delete cascade,
  views       integer not null default 0,
  created_at  timestamptz default now() not null
);

create table if not exists public.assignments (
  id           uuid primary key default gen_random_uuid(),
  course_id    uuid references public.courses(id) on delete cascade,
  title        text not null,
  subject      text not null default '',
  description  text not null default '',
  instructions text not null default '',
  file_url     text not null default '',
  file_name    text not null default '',
  deadline     timestamptz not null,
  total_marks  integer not null default 100,
  created_by   uuid not null references public.profiles(id) on delete cascade,
  ai_generated boolean not null default false,
  created_at   timestamptz default now() not null
);

create table if not exists public.submissions (
  id             uuid primary key default gen_random_uuid(),
  assignment_id  uuid not null references public.assignments(id) on delete cascade,
  student_id     uuid not null references public.profiles(id) on delete cascade,
  student_name   text not null default '',
  file_url       text not null default '',
  file_name      text not null default '',
  submitted_at   timestamptz default now() not null,
  status         submission_status not null default 'submitted',
  marks_obtained integer,
  feedback       text,
  graded_by      uuid references public.profiles(id) on delete set null,
  graded_at      timestamptz,
  unique(assignment_id, student_id)
);

create table if not exists public.quizzes (
  id               uuid primary key default gen_random_uuid(),
  course_id        uuid references public.courses(id) on delete cascade,
  title            text not null,
  subject          text not null default '',
  description      text not null default '',
  questions        jsonb not null default '[]',
  duration_minutes integer not null default 15,
  total_marks      integer not null default 10,
  deadline         timestamptz,
  created_by       uuid not null references public.profiles(id) on delete cascade,
  ai_generated     boolean not null default false,
  created_at       timestamptz default now() not null
);

create table if not exists public.quiz_attempts (
  id           uuid primary key default gen_random_uuid(),
  quiz_id      uuid not null references public.quizzes(id) on delete cascade,
  student_id   uuid not null references public.profiles(id) on delete cascade,
  student_name text not null default '',
  answers      jsonb not null default '{}',
  score        integer not null default 0,
  total_marks  integer not null default 10,
  status       text not null default 'submitted',
  ai_feedback  text,
  ai_evaluated boolean not null default false,
  created_at   timestamptz default now() not null
);

create table if not exists public.study_sessions (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid not null references public.profiles(id) on delete cascade,
  planned_duration_seconds integer not null,
  elapsed_seconds          integer not null default 0,
  status                   session_status not null default 'active',
  violations               integer not null default 0,
  camera_enabled           boolean not null default false,
  valid_session            boolean not null default false,
  blocked_apps             jsonb not null default '[]',
  started_at               timestamptz default now() not null,
  ended_at                 timestamptz
);

create table if not exists public.game_state (
  user_id        uuid primary key references public.profiles(id) on delete cascade,
  points         integer not null default 0,
  streak         integer not null default 0,
  longest_streak integer not null default 0,
  last_session_date date,
  badges         jsonb not null default '[]',
  challenges     jsonb not null default '[]',
  updated_at     timestamptz default now() not null
);

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  message    text not null,
  type       text not null default 'info',
  is_read    boolean not null default false,
  created_at timestamptz default now() not null
);

-- ── Indexes ────────────────────────────────────────────────────
create index if not exists idx_lectures_course on public.lectures(course_id);
create index if not exists idx_assignments_course on public.assignments(course_id);
create index if not exists idx_submissions_assignment on public.submissions(assignment_id);
create index if not exists idx_submissions_student on public.submissions(student_id);
create index if not exists idx_quiz_attempts_quiz on public.quiz_attempts(quiz_id);
create index if not exists idx_quiz_attempts_student on public.quiz_attempts(student_id);
create index if not exists idx_study_sessions_user on public.study_sessions(user_id);
create index if not exists idx_login_events_user on public.login_events(user_id);
create index if not exists idx_notifications_user on public.notifications(user_id);
create index if not exists idx_enrollments_student on public.enrollments(student_id);
create index if not exists idx_enrollments_course on public.enrollments(course_id);

-- ── Trigger: increment_lecture_views ──────────────────────────
create or replace function public.increment_lecture_views(lecture_id uuid)
returns void language sql security definer as $$
  update public.lectures set views = views + 1 where id = lecture_id;
$$;

-- ── Trigger: auto-create profile on signup ─────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, email, full_name, created_at, updated_at)
  values(new.id, new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    now(), now());

  insert into public.user_roles(user_id, role) values(new.id, 'student');

  insert into public.game_state(user_id, points, streak, badges, challenges)
  values(new.id, 0, 0,
    '[{"id":"first_session","name":"First Step","description":"Complete your first study session","icon":"award","unlocked":false},
      {"id":"streak_3","name":"On a Roll","description":"Maintain a 3-day streak","icon":"flame","unlocked":false},
      {"id":"streak_7","name":"Week Warrior","description":"7-day streak","icon":"flame","unlocked":false},
      {"id":"hours_10","name":"Dedicated","description":"Study 10 hours total","icon":"book","unlocked":false},
      {"id":"hours_50","name":"Scholar","description":"Study 50 hours total","icon":"library","unlocked":false},
      {"id":"no_violations","name":"Laser Focus","description":"Session with zero violations","icon":"eye","unlocked":false},
      {"id":"long_session","name":"Deep Work","description":"Complete a 2-hour session","icon":"time","unlocked":false},
      {"id":"early_bird","name":"Early Bird","description":"Study before 8am","icon":"sunny","unlocked":false}]'::jsonb,
    '[{"id":"daily_1h","title":"Daily Focus","description":"Study for 1 hour today","target":3600,"current":0,"unit":"seconds","reward":50,"completed":false},
      {"id":"week_5h","title":"Weekly Goal","description":"5 hours this week","target":18000,"current":0,"unit":"seconds","reward":200,"completed":false},
      {"id":"sessions_5","title":"Session Streak","description":"Complete 5 sessions","target":5,"current":0,"unit":"sessions","reward":100,"completed":false}]'::jsonb
  );
  return new;
end;$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── RLS ────────────────────────────────────────────────────────
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.login_events enable row level security;
alter table public.courses enable row level security;
alter table public.enrollments enable row level security;
alter table public.lectures enable row level security;
alter table public.assignments enable row level security;
alter table public.submissions enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.study_sessions enable row level security;
alter table public.game_state enable row level security;
alter table public.notifications enable row level security;

-- profiles
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select
  using(id=auth.uid() or public.has_role(auth.uid(),'admin'));
drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update" on public.profiles for update
  using(id=auth.uid()) with check(id=auth.uid());
drop policy if exists "profiles_admin" on public.profiles;
create policy "profiles_admin" on public.profiles for all
  using(public.has_role(auth.uid(),'admin'));

-- user_roles
drop policy if exists "roles_select" on public.user_roles;
create policy "roles_select" on public.user_roles for select
  using(user_id=auth.uid() or public.has_role(auth.uid(),'admin'));
drop policy if exists "roles_admin" on public.user_roles;
create policy "roles_admin" on public.user_roles for all
  using(public.has_role(auth.uid(),'admin'));

-- login_events
drop policy if exists "events_insert" on public.login_events;
create policy "events_insert" on public.login_events for insert
  with check(user_id=auth.uid());
drop policy if exists "events_admin" on public.login_events;
create policy "events_admin" on public.login_events for select
  using(public.has_role(auth.uid(),'admin'));

-- courses
drop policy if exists "courses_select" on public.courses;
create policy "courses_select" on public.courses for select
  using(auth.uid() is not null);
drop policy if exists "courses_insert" on public.courses;
create policy "courses_insert" on public.courses for insert
  with check(public.has_role(auth.uid(),'lecturer') and lecturer_id=auth.uid());
drop policy if exists "courses_update" on public.courses;
create policy "courses_update" on public.courses for update
  using(lecturer_id=auth.uid() or public.has_role(auth.uid(),'admin'));
drop policy if exists "courses_admin" on public.courses;
create policy "courses_admin" on public.courses for all
  using(public.has_role(auth.uid(),'admin'));

-- enrollments
drop policy if exists "enroll_select" on public.enrollments;
create policy "enroll_select" on public.enrollments for select
  using(student_id=auth.uid() or public.has_role(auth.uid(),'admin') or
    exists(select 1 from public.courses c where c.id=course_id and c.lecturer_id=auth.uid()));
drop policy if exists "enroll_insert" on public.enrollments;
create policy "enroll_insert" on public.enrollments for insert
  with check(student_id=auth.uid());
drop policy if exists "enroll_delete" on public.enrollments;
create policy "enroll_delete" on public.enrollments for delete
  using(student_id=auth.uid());

-- lectures
drop policy if exists "lectures_select" on public.lectures;
create policy "lectures_select" on public.lectures for select
  using(auth.uid() is not null);
drop policy if exists "lectures_insert" on public.lectures;
create policy "lectures_insert" on public.lectures for insert
  with check(public.has_role(auth.uid(),'lecturer') and uploaded_by=auth.uid());
drop policy if exists "lectures_update" on public.lectures;
create policy "lectures_update" on public.lectures for update
  using(uploaded_by=auth.uid() or public.has_role(auth.uid(),'admin'));
drop policy if exists "lectures_delete" on public.lectures;
create policy "lectures_delete" on public.lectures for delete
  using(uploaded_by=auth.uid() or public.has_role(auth.uid(),'admin'));

-- assignments
drop policy if exists "assign_select" on public.assignments;
create policy "assign_select" on public.assignments for select
  using(auth.uid() is not null);
drop policy if exists "assign_insert" on public.assignments;
create policy "assign_insert" on public.assignments for insert
  with check(public.has_role(auth.uid(),'lecturer') and created_by=auth.uid());
drop policy if exists "assign_update" on public.assignments;
create policy "assign_update" on public.assignments for update
  using(created_by=auth.uid() or public.has_role(auth.uid(),'admin'));
drop policy if exists "assign_delete" on public.assignments;
create policy "assign_delete" on public.assignments for delete
  using(created_by=auth.uid() or public.has_role(auth.uid(),'admin'));

-- submissions
drop policy if exists "sub_select" on public.submissions;
create policy "sub_select" on public.submissions for select
  using(student_id=auth.uid() or public.has_role(auth.uid(),'admin') or
    exists(select 1 from public.assignments a join public.courses c on c.id=a.course_id
      where a.id=assignment_id and c.lecturer_id=auth.uid()));
drop policy if exists "sub_insert" on public.submissions;
create policy "sub_insert" on public.submissions for insert
  with check(student_id=auth.uid());
drop policy if exists "sub_update" on public.submissions;
create policy "sub_update" on public.submissions for update
  using(exists(select 1 from public.assignments a join public.courses c on c.id=a.course_id
    where a.id=assignment_id and c.lecturer_id=auth.uid()) or public.has_role(auth.uid(),'admin'));

-- quizzes
drop policy if exists "quiz_select" on public.quizzes;
create policy "quiz_select" on public.quizzes for select
  using(auth.uid() is not null);
drop policy if exists "quiz_insert" on public.quizzes;
create policy "quiz_insert" on public.quizzes for insert
  with check(public.has_role(auth.uid(),'lecturer') and created_by=auth.uid());
drop policy if exists "quiz_update" on public.quizzes;
create policy "quiz_update" on public.quizzes for update
  using(created_by=auth.uid() or public.has_role(auth.uid(),'admin'));
drop policy if exists "quiz_admin" on public.quizzes;
create policy "quiz_admin" on public.quizzes for all
  using(public.has_role(auth.uid(),'admin'));

-- quiz_attempts
drop policy if exists "attempt_select" on public.quiz_attempts;
create policy "attempt_select" on public.quiz_attempts for select
  using(student_id=auth.uid() or public.has_role(auth.uid(),'admin') or
    exists(select 1 from public.quizzes q join public.courses c on c.id=q.course_id
      where q.id=quiz_id and c.lecturer_id=auth.uid()));
drop policy if exists "attempt_insert" on public.quiz_attempts;
create policy "attempt_insert" on public.quiz_attempts for insert
  with check(student_id=auth.uid());
drop policy if exists "attempt_update" on public.quiz_attempts;
create policy "attempt_update" on public.quiz_attempts for update
  using(exists(select 1 from public.quizzes q join public.courses c on c.id=q.course_id
    where q.id=quiz_id and c.lecturer_id=auth.uid()) or public.has_role(auth.uid(),'admin'));

-- study_sessions
drop policy if exists "session_all" on public.study_sessions;
create policy "session_all" on public.study_sessions for all
  using(user_id=auth.uid() or public.has_role(auth.uid(),'admin'))
  with check(user_id=auth.uid());

-- game_state
drop policy if exists "game_all" on public.game_state;
create policy "game_all" on public.game_state for all
  using(user_id=auth.uid() or public.has_role(auth.uid(),'admin'))
  with check(user_id=auth.uid());

-- notifications
drop policy if exists "notif_select" on public.notifications;
create policy "notif_select" on public.notifications for select
  using(user_id=auth.uid());
drop policy if exists "notif_update" on public.notifications;
create policy "notif_update" on public.notifications for update
  using(user_id=auth.uid());
drop policy if exists "notif_insert" on public.notifications;
create policy "notif_insert" on public.notifications for insert
  with check(user_id=auth.uid() or public.has_role(auth.uid(),'admin') or public.has_role(auth.uid(),'lecturer'));

-- ── Storage Buckets ────────────────────────────────────────────
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values
  ('avatars','avatars',true,2097152,array['image/jpeg','image/png','image/webp']),
  ('lecture-files','lecture-files',false,52428800,array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation']),
  ('assignment-files','assignment-files',false,20971520,array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
  ('submissions','submissions',false,20971520,array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/zip'])
on conflict(id) do nothing;

drop policy if exists "avatars_read" on storage.objects;
create policy "avatars_read" on storage.objects for select using(bucket_id='avatars');
drop policy if exists "avatars_upload" on storage.objects;
create policy "avatars_upload" on storage.objects for insert
  with check(bucket_id='avatars' and auth.uid()::text=(storage.foldername(name))[1]);
drop policy if exists "lecture_read" on storage.objects;
create policy "lecture_read" on storage.objects for select
  using(bucket_id='lecture-files' and auth.uid() is not null);
drop policy if exists "lecture_upload" on storage.objects;
create policy "lecture_upload" on storage.objects for insert
  with check(bucket_id='lecture-files' and public.has_role(auth.uid(),'lecturer'));
drop policy if exists "assignment_read" on storage.objects;
create policy "assignment_read" on storage.objects for select
  using(bucket_id='assignment-files' and auth.uid() is not null);
drop policy if exists "assignment_upload" on storage.objects;
create policy "assignment_upload" on storage.objects for insert
  with check(bucket_id='assignment-files' and public.has_role(auth.uid(),'lecturer'));
drop policy if exists "submissions_access" on storage.objects;
create policy "submissions_access" on storage.objects for select
  using(bucket_id='submissions' and (
    public.has_role(auth.uid(),'lecturer') or public.has_role(auth.uid(),'admin') or
    auth.uid()::text=(storage.foldername(name))[1]));
drop policy if exists "submissions_upload" on storage.objects;
create policy "submissions_upload" on storage.objects for insert
  with check(bucket_id='submissions' and auth.uid()::text=(storage.foldername(name))[1]);
drop policy if exists "storage_admin" on storage.objects;
create policy "storage_admin" on storage.objects for all
  using(public.has_role(auth.uid(),'admin'));

-- ============================================================
-- PHASE 2: Attendance Tables (Added by audit upgrade)
-- ============================================================

CREATE TABLE IF NOT EXISTS attendance (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id       uuid REFERENCES courses(id) ON DELETE CASCADE,
  student_id      uuid REFERENCES profiles(id) ON DELETE CASCADE,
  student_name    text NOT NULL DEFAULT '',
  lecturer_id     uuid REFERENCES profiles(id),
  status          text NOT NULL DEFAULT 'absent'
                  CHECK (status IN ('present','absent','late','excused')),
  date            date NOT NULL,
  remarks         text,
  created_at      timestamptz DEFAULT now(),
  UNIQUE (course_id, student_id, date)
);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students view own attendance"
  ON attendance FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Lecturers manage attendance"
  ON attendance FOR ALL
  USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('lecturer','admin'))
  );

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);

-- ============================================================
-- GPA / Grades view
-- ============================================================
-- GPA is computed client-side from quiz_attempts + submissions
-- No extra table needed; use existing quiz_attempts table.
