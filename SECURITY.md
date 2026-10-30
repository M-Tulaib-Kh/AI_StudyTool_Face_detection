# Security

## Reporting a vulnerability
Please email the maintainer privately (see the GitHub profile) instead of opening a public issue.

## Security model
- **Secrets:** the app ships only the public Supabase URL and anon key (injected with
  `--dart-define-from-file`). The Groq key exists only as a Supabase Edge Function secret.
- **AI proxy:** `supabase/functions/ai-proxy` verifies the user's JWT, builds prompts on the
  server from a fixed set of tasks, validates and size-limits input, rate-limits per user
  (`ai_usage`), and only lets lecturers/admins grade submissions.
- **Database:** Row Level Security is enabled on every table. Migration `002` additionally
  enforces server-side quiz scoring, blocks self-grading of submissions, restricts attendance
  writes to the course lecturer, fixes `search_path` on `SECURITY DEFINER` functions and removes
  anonymous access to them.
- **Roles:** roles can only be changed by an admin. Lecturer signups create a *pending request*.
- **Camera:** frames are analysed on-device with ML Kit; they are not uploaded.

## Known limitations (be honest about them)
1. **Quiz answer keys are readable by students.** `quizzes.questions` contains `correctAnswer`
   and every authenticated user may `select` quizzes. Recommended fix: store keys in a
   lecturer-only table and grade through a `security definer` function.
2. **Gamification is client-authoritative.** `study_sessions` and `game_state` are written by the
   client (own rows only), so a determined user can inflate their own points/streaks.
3. **Submission files:** any lecturer can read files in the `submissions` bucket (paths contain
   random UUIDs). Scope reads by course if stricter isolation is required.
4. **Release builds** keep R8/minification disabled until it has been tested against all plugins.
