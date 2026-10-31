# StudyLock — AI Study Focus Platform

Flutter + Supabase app that helps students stay focused (on-device face detection during study
sessions) and gives lecturers AI-assisted quizzes, assignments and grading. Roles: student,
lecturer, admin.

## Features
- Focus sessions with on-device face detection (Google ML Kit): face missing, eyes closed, app left
- AI quiz / assignment generation and submission grading (Groq, via a Supabase Edge Function)
- Courses, lectures, assignments, submissions, quizzes, attendance, GPA, timetable, analytics
- Gamification: points, streaks, badges, challenges
- Role-based access (student / lecturer / admin) enforced by Row Level Security

## Architecture
```
Flutter app ──(anon key + user JWT)──► Supabase (Postgres + RLS, Auth, Storage)
     └────────► Edge Function `ai-proxy` ──(GROQ_API_KEY secret)──► Groq API
```
The app never contains an AI key. See [SECURITY.md](SECURITY.md).

## Setup

### 1. Supabase
1. Create a project, then run `supabase/migrations/001_full_schema.sql` and
   `supabase/migrations/002_security_hardening.sql` in the SQL editor (in that order).
2. Create the first admin: sign up in the app, then in the SQL editor run
   `update public.user_roles set role = 'admin' where user_id = '<your-user-id>';`

### 2. AI Edge Function (Groq)
Get a key at https://console.groq.com, then with the [Supabase CLI](https://supabase.com/docs/guides/cli):
```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase secrets set GROQ_API_KEY=<your-groq-key>
supabase functions deploy ai-proxy
```
Optional secrets: `GROQ_MODEL` (default `llama-3.3-70b-versatile`), `AI_HOURLY_LIMIT` (default 30).

### 3. App configuration
```bash
cp env.example.json env.json   # then fill in SUPABASE_URL and SUPABASE_ANON_KEY
flutter pub get
flutter run --dart-define-from-file=env.json
```
`env.json` is git-ignored. Only public values go there.

## Build
```bash
flutter build apk --release --dart-define-from-file=env.json
flutter build web --release --dart-define-from-file=env.json
```

### Release signing (Android)
Create `android/key.properties` (git-ignored):
```
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```
Without it, release builds fall back to the debug key (local testing only).

## Quality
```bash
flutter analyze
flutter test
```
CI (`.github/workflows/ci.yml`) runs analyze, tests and a type-check of the Edge Function.

## Project layout
```
lib/core        theme, router, config
lib/data        models
lib/providers   Riverpod state
lib/services    AI, storage, notifications, cache, logging
lib/features    auth, student, lecturer, admin, session, attendance, ...
supabase/       migrations + Edge Functions
```

## License
Proprietary — all rights reserved. See [LICENSE](LICENSE).
