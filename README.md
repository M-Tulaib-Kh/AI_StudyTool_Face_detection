# 🎓 StudyLock V2

**AI-Powered Academic Focus Platform**  
Flutter + Supabase + Riverpod + Gemini AI

---

## 🚀 Quick Setup

### 1. Prerequisites
- Flutter 3.24+ (`flutter --version`)
- Android Studio with Redmi Note 13 USB debugging enabled
- Supabase project — [supabase.com](https://supabase.com)
- Gemini API key — [aistudio.google.com](https://aistudio.google.com/app/apikey)

### 2. Clone & Configure
```bash
git clone <your-repo>
cd studylock_v2

# Copy env template
cp .env.example .env
# Edit .env with your real keys
```

### 3. Set up Supabase
```bash
# Run the SQL migration in Supabase SQL Editor
# File: supabase/migrations/001_full_schema.sql
```

### 4. Run on Redmi Note 13
```bash
# Enable USB Debugging on phone:
# Settings → About Phone → tap MIUI Version 7 times → Developer Options → USB Debugging ON

flutter pub get
flutter run  # auto-detects connected device
```

### 5. Build for Android
```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK
flutter build apk --release --split-per-abi

# App Bundle (Play Store)
flutter build appbundle --release
```

### 6. Build for Web (Admin Panel)
```bash
flutter build web --web-renderer html --release
# Output: build/web/ — deploy to Firebase Hosting / Vercel / Netlify
```

---

## 📱 Running Admin Panel on Web

The admin panel works fully in Chrome:

```bash
flutter run -d chrome --web-renderer html
```

Navigate to `/admin` — requires admin role account.

---

## 🔐 First-Time Admin Setup

Since admin self-registration is blocked (security), create the first admin manually:

1. Register a new account normally (as student/lecturer)
2. In Supabase Dashboard → Table Editor → `user_roles`
3. Find your user row and change `role` to `admin`
4. Sign out and sign back in

---

## 🖼️ App Icon & Splash Screen

Place your icon at `assets/images/app_icon.png` (1024×1024 PNG, no alpha channel), then:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 📁 Project Structure

```
lib/
├── core/          → Config, Router, Theme, Constants
├── data/          → Models, Service re-exports
├── features/      → Screens by feature (admin, student, lecturer…)
├── providers/     → Riverpod StateNotifiers (business logic)
├── services/      → Gemini AI, Storage, Notifications, Realtime
└── shared/        → Reusable widgets (AppButton, ShimmerLoader…)
```

---

## 🏗️ Architecture

- **State**: Riverpod (StateNotifier + Provider + FutureProvider)
- **Navigation**: GoRouter (role-based redirects)
- **Backend**: Supabase (Auth + Database + Storage + Realtime)
- **AI**: Google Gemini 2.0 Flash
- **Face Detection**: ML Kit (on-device, offline)

---

## ⚠️ Security Checklist

- [ ] `.env` is in `.gitignore` ✅
- [ ] Admin self-registration blocked ✅
- [ ] File upload validation enabled ✅
- [ ] Supabase RLS policies active ✅
- [ ] Rotate API keys if ever exposed ⚠️

---

## 📋 Roles

| Role | Access |
|---|---|
| **Student** | Home, Courses, Sessions, Attendance, GPA, Leaderboard, AI Tutor, Timetable |
| **Lecturer** | Create content, Mark attendance, Grade submissions, Performance stats |
| **Admin** | All above + Analytics dashboard, User management, Course management |

---

## 🐛 Common Issues

**Camera not working on Redmi?**  
Settings → Apps → StudyLock → Permissions → Camera → Allow

**App killed during session?**  
Settings → Apps → StudyLock → Battery → No restrictions

**Notifications not showing?**  
Settings → Notifications → StudyLock → Allow notifications

---

*StudyLock V2 — Built with Flutter 3.44 | June 2026*

ALL RIGHTS RESERVED FOR | M TULAIB KH  

