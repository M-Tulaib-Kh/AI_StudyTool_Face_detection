# StudyLock V2 — Professional Software Engineering Audit Report
**Date:** June 2026 | **Auditor:** Senior Flutter Engineer  
**Project:** StudyLock — AI-Powered Academic Focus Platform

---

## PROJECT HEALTH SCORE

| Category | Score | Grade |
|---|---|---|
| **Architecture** | 8.0/10 | ✅ Good |
| **Security** | 5.5/10 | ⚠️ Needs Work |
| **Performance** | 7.5/10 | ✅ Good |
| **Maintainability** | 8.0/10 | ✅ Good |
| **Scalability** | 7.5/10 | ✅ Good |
| **Production Readiness** | 6.5/10 | ⚠️ Needs Work |
| **OVERALL** | **7.2/10** | ✅ Good |

---

## 1. ERROR ANALYSIS

### ❌ CRITICAL ISSUES (Fixed in this build)

---

**Issue 1: Real API Keys Exposed in .env**
- File: `.env`
- Type: CRITICAL SECURITY VULNERABILITY
- Impact: Anyone with your Git repo access can steal your Supabase database and Gemini credits
- Fix Applied: ✅ `.gitignore` created — `.env` is now excluded from all git commits
- Action Required: IMMEDIATELY rotate your Supabase anon key and Gemini API key

---

**Issue 2: Admin Self-Registration (Security)**
- File: `lib/features/auth/screens/register_screen.dart`, Line 97
- Type: Security — Privilege Escalation
- Why: `UserRole.values` included `admin` in the public signup form — anyone could sign up as admin
- Fix Applied: ✅ Only `[UserRole.student, UserRole.lecturer]` are now shown in the public register screen

---

**Issue 3: Dead Code — Duplicate Widget Exports**
- Files: `lib/widgets/gradient_button.dart`, `lib/widgets/loading_screen.dart`
- Type: Dead Code
- Why: These were simple re-export stubs for `lib/shared/widgets/` that were never used
- Fix Applied: ✅ Both files deleted

---

**Issue 4: Orphan Re-export File**
- File: `lib/models/models.dart` (just `export '../data/models/models.dart'`)
- Type: Dead Code / Confusion Risk
- Fix Applied: ✅ File deleted — use `lib/data/models/models.dart` directly

---

**Issue 5: Unused Variable in admin_dashboard_screen.dart**
- File: `lib/features/admin/screens/admin_dashboard_screen.dart`, Line 44
- Code: `final students = 0; // simplified count` — declared but never used
- Type: Compile Warning (unused_local_variable)
- Fix Applied: ✅ Removed

---

**Issue 6: Missing .gitignore**
- File: Root directory
- Type: CRITICAL SECURITY
- Impact: Every git commit was exposing `.env` with real API keys, Supabase URL, passwords
- Fix Applied: ✅ Full `.gitignore` created covering Dart, Android, iOS, .env

---

### ⚠️ WARNINGS (Non-breaking)

---

**Issue 7: Dual Service Paths (Confusing, not breaking)**
- Pattern: `lib/services/X.dart` and `lib/data/services/X.dart` for gemini, notification, storage
- The data/services files are re-exports pointing to lib/services files — pattern works but confusing
- Recommendation: Standardize all imports to `lib/services/` in new code

---

**Issue 8: session_active_screen.dart — Camera not disposed on web**
- File: `lib/features/session/screens/session_active_screen.dart`
- `dart:io` is used for temp file deletion — safe on Android/iOS but would crash on web
- The file correctly only initializes camera when `session.cameraEnabled` but the `dart:io` import is unconditional
- Risk: LOW (camera feature is Android/iOS only)

---

**Issue 9: GPA Provider — `ref.read(academicProvider)` inside StateNotifier**
- File: `lib/providers/gpa_provider.dart`
- Pattern: Reading another provider inside `StateNotifier` constructor is fragile
- Should use `ref.watch()` or `ref.listen()` for reactive updates
- Risk: MEDIUM — GPA may not update when quiz results change

---

**Issue 10: Realtime Service — No error recovery**
- File: `lib/services/realtime/realtime_service.dart`
- Realtime channels don't reconnect on network loss
- Risk: MEDIUM — Live updates stop after 60s disconnect

---

**Issue 11: Missing null check on notification plugin**
- File: `lib/data/services/notification_service.dart`
- `_plugin` is `late` — if `showNotification` is called before `initialize()`, it throws
- Risk: LOW — initialize() always called in main.dart first

---

**Issue 12: `context.go()` after async in session_active_screen**
- After `endSession()`, `context.go()` is called without `mounted` check in one path
- File: `lib/features/session/screens/session_active_screen.dart`, line ~134
- Already has `if (mounted)` check — ✅ OK

---

### ℹ️ INFO / STYLE ISSUES

- `lib/features/admin/screens/admin_courses_screen.dart` imports `go_router` but doesn't use it
- Several screens repeat the same AppBar pattern — could be a shared widget
- `analytics_provider.dart` fetches data with `Future.wait` of 8 queries — good pattern

---

## 2. ANDROID AUDIT

### ✅ PASS — Android V2 Embedding

```kotlin
// MainActivity.kt
class MainActivity: FlutterActivity() // ✅ V2 embedding (FlutterActivity)
```
- No `FlutterFragmentActivity` or old V1 `FlutterView` references
- `@MainThread` annotations not needed — Flutter handles this

### ✅ Build Configuration

| Setting | Value | Status |
|---|---|---|
| compileSdk | 35 (Android 15) | ✅ Latest |
| targetSdk | 35 | ✅ |
| minSdk | 21 (Android 5.0) | ✅ Wide compatibility |
| Kotlin | 1.9.24 | ✅ |
| AGP | 8.5.2 | ✅ |
| Gradle | 8.10.2 | ✅ |
| Java | 17 | ✅ Required by Flutter 3.x |
| NDK | 27.0.12077973 | ✅ ML Kit compatible |
| coreLibraryDesugaring | Enabled | ✅ Required for Java 8+ APIs on older Android |
| multiDexEnabled | true | ✅ Required for large app |

### ✅ AndroidManifest.xml Review

| Permission | Status | Reason |
|---|---|---|
| INTERNET | ✅ | Supabase, AI |
| CAMERA | ✅ | Face detection |
| READ_MEDIA_IMAGES | ✅ | Android 13+ |
| POST_NOTIFICATIONS | ✅ | Android 13+ required |
| SCHEDULE_EXACT_ALARM | ✅ | Study reminders |
| RECORD_AUDIO | ✅ | Voice-to-notes |
| VIBRATE | ✅ | Violation alerts |

### ⚠️ Missing: `android:networkSecurityConfig`

For production, add network security config to block cleartext traffic and certificate pinning.

---

## 3. DEVICE COMPATIBILITY — Redmi Note 13 (Android 14, API 34)

| Feature | Status | Notes |
|---|---|---|
| Camera (front) | ✅ Supported | ML Kit face detection works |
| Face Detection | ✅ ML Kit handles it | Needs good lighting |
| Notifications | ✅ POST_NOTIFICATIONS declared | Android 13+ requires runtime permission |
| File Picker | ✅ | READ_MEDIA_IMAGES for Android 13+ included |
| Storage | ✅ | Scoped storage compliant |
| Background Services | ⚠️ Limited | Redmi has aggressive battery optimization — user must whitelist app |
| USB Debugging | ✅ | applicationIdSuffix ".debug" for debug builds |
| MIUI Overlay Detection | ⚠️ | MIUI may restrict camera access during screen lock |

### Redmi-Specific Recommendations:
1. In app, guide users to disable "Battery Saver" for StudyLock in MIUI settings
2. Prompt user to grant "Display over other apps" for session monitoring
3. Test face detection in low-light — Redmi Note 13 camera is adequate but add brightness hint

---

## 4. PERFORMANCE AUDIT

### ✅ Good Patterns Found
- `ref.watch()` used correctly in all screens (triggers rebuilds only when needed)
- `autoDispose` used in FutureProviders (ranking, timetable, parent portal)
- `shimmer` loading states implemented
- Image caching via `CachedNetworkImage` package available

### ⚠️ Improvement Opportunities

| Issue | File | Recommendation |
|---|---|---|
| `loadAll()` fetches ALL courses/lectures/assignments in one call | `academic_provider.dart` | Add pagination for large datasets |
| `admin_users_screen` re-fetches all users on every filter change | `admin_users_screen.dart` | Cache result, filter client-side (already does this) |
| `analytics_provider` runs 8 parallel queries | `analytics_provider.dart` | Good, but cache result for 5 minutes |
| `ranking_screen` fetches profiles one-by-one in a loop | `ranking_screen.dart` | Use a SQL join or RPC instead |
| Session timer rebuilds entire widget every second | `session_provider.dart` | ✅ OK — only `elapsedSeconds` changes, minimal impact |
| Camera preview renders even when minimized | `session_active_screen.dart` | `pausePreview()` called in `didChangeAppLifecycleState` ✅ |

### Fix: Ranking Screen N+1 Query Problem
The ranking screen fetches each user's profile in a loop (N queries). Should use a single JOIN.

---

## 5. SECURITY AUDIT

| Risk | Severity | Status |
|---|---|---|
| Real API keys in `.env` | 🔴 CRITICAL | ⚠️ Keys are live — rotate them NOW |
| `.env` not in `.gitignore` | 🔴 CRITICAL | ✅ Fixed — `.gitignore` now added |
| Admin self-registration | 🔴 HIGH | ✅ Fixed — admin removed from public signup |
| Supabase RLS on all tables | 🟡 MEDIUM | Schema has RLS — verify each policy in Supabase dashboard |
| JWT auto-refresh | ✅ LOW | `autoRefreshToken: true` set |
| Secure storage for tokens | ✅ LOW | Supabase handles tokens internally |
| File upload validation | ✅ LOW | File type and size checks in StorageService |
| Prompt injection in AI | ✅ LOW | `_safe()` method strips injection patterns in GeminiService |

### 🚨 IMMEDIATE ACTION REQUIRED:
1. Go to Supabase Dashboard → Settings → API → Regenerate anon key
2. Go to Google AI Studio → Regenerate Gemini API key
3. Update your `.env` file with new keys
4. Since `.gitignore` now exists, run: `git rm --cached .env` to remove it from git history

---

## 6. PUBLISHING READINESS — Google Play Store

### ❌ Missing for Production

| Item | Status | Action |
|---|---|---|
| App signing keystore | ❌ Missing | `keytool -genkey -v -keystore studylock.jks` |
| `key.properties` file | ❌ Missing | Create with keystore details |
| Release signing in build.gradle | ⚠️ Uses debug signing | Add proper signingConfigs |
| App icon (all densities) | ❌ Missing | Use flutter_launcher_icons package |
| Adaptive icon | ❌ Missing | Required for Android 8+ |
| Splash screen | ❌ Missing | Use flutter_native_splash package |
| ProGuard/R8 rules | ⚠️ Disabled | Enable for production |
| Privacy Policy URL | ❌ Missing | Required for Play Store |
| Target API 34+ | ✅ targetSdk 35 | Good |
| 64-bit support | ✅ NDK configured | Good |
| App bundle (.aab) | ❌ Not built yet | `flutter build appbundle` |

### Production Checklist:
```bash
# 1. Create keystore
keytool -genkey -v -keystore ~/studylock.jks -keyalg RSA -keysize 2048 -validity 10000 -alias studylock

# 2. Build release
flutter build appbundle --release

# 3. Test release
flutter build apk --release --split-per-abi

# 4. Verify no debug info
flutter build apk --obfuscate --split-debug-info=build/debug-info
```

---

## 7. APP ICON & SPLASH SCREEN

### Step 1: Add flutter_launcher_icons

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1
  flutter_native_splash: ^2.4.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app_icon.png"  # 1024x1024 PNG, no alpha
  adaptive_icon_background: "#060E1A"
  adaptive_icon_foreground: "assets/images/app_icon_fg.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/images/app_icon.png"

flutter_native_splash:
  color: "#060E1A"
  image: assets/images/splash_logo.png
  android_12:
    color: "#060E1A"
    image: assets/images/splash_logo.png
  fullscreen: false
```

### Step 2: Generate

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Icon Requirements:
- App Icon: **1024×1024 PNG**, no rounded corners, no alpha channel
- Foreground (adaptive): **1024×1024**, subject in center 66% of canvas
- Colors: Background `#060E1A` (dark navy), icon in `#5B8FF9` (StudyLock blue)

---

## 8. WEB VERSION

### Status: ✅ Basic web files now created

### Web-Specific Issues:
| Issue | Impact | Fix |
|---|---|---|
| Camera (ML Kit) — not available on web | HIGH | Disable camera feature on web, show message |
| `dart:io` File usage in session_active_screen | HIGH | Already guarded by camera check |
| `sqflite` — not supported on web | MEDIUM | Use `shared_preferences` fallback (already in offline_cache_service) |
| `flutter_local_notifications` — limited web support | MEDIUM | Use browser notifications API |
| PDF viewer (syncfusion) — web supported | ✅ OK | Works on web |

### Admin Web Panel — Works Fully ✅
The admin panel (`/admin`, `/admin/users`, `/admin/courses`, `/analytics`) is:
- Pure Flutter + Supabase — no native dependencies
- Can run on web with `flutter run -d chrome`
- Responsive enough for desktop browsers
- Deep links work via GoRouter's web URL handling

### To run admin panel on web:
```bash
flutter run -d chrome --web-renderer html
# Or build:
flutter build web --web-renderer html --release
```

### Web Responsiveness Improvements Needed:
- Admin dashboard grid: 2 columns on mobile, 4 on desktop
- Add `LayoutBuilder` or `MediaQuery` breakpoints for wide screens

---

## 9. PROJECT DOCUMENTATION

### Architecture
```
StudyLock V2 — Clean Architecture (Feature-First)

lib/
├── core/              ← App-wide config, constants, routing, theme
│   ├── config/        ← Supabase + env setup
│   ├── constants/     ← AppConstants, AppRoutes
│   ├── router/        ← GoRouter with role-based redirects
│   ├── theme/         ← AppTheme (dark/light), AppColors
│   └── utils/         ← String/Date/Int extensions
│
├── data/              ← Data layer
│   ├── models/        ← All Dart data models (Supabase ↔ Dart)
│   └── services/      ← Re-export stubs pointing to lib/services/
│
├── features/          ← Feature modules (UI layer)
│   ├── admin/         ← Admin screens (dashboard, users, courses)
│   ├── ai_tutor/      ← AI chat tutor
│   ├── analytics/     ← Analytics dashboard
│   ├── attendance/    ← Attendance tracking
│   ├── auth/          ← Login, register, forgot password, onboarding
│   ├── gpa/           ← GPA calculator
│   ├── lecturer/      ← Lecturer screens
│   ├── parent/        ← Parent portal
│   ├── ranking/       ← Student leaderboard
│   ├── session/       ← Study session with face detection
│   ├── settings/      ← Settings (theme, language, notifications)
│   ├── student/       ← Student screens
│   ├── theme/         ← ThemeMode + Language providers
│   └── timetable/     ← Weekly timetable
│
├── providers/         ← Riverpod StateNotifiers (business logic)
│   ├── academic_provider.dart   ← Courses, lectures, assignments, quizzes
│   ├── analytics_provider.dart  ← Admin analytics data
│   ├── attendance_provider.dart ← Attendance CRUD
│   ├── auth_provider.dart       ← Authentication state
│   ├── game_provider.dart       ← XP, badges, challenges
│   ├── gpa_provider.dart        ← GPA computation
│   └── session_provider.dart   ← Study session timer + Supabase sync
│
├── services/          ← Business services (canonical)
│   ├── ai_*.dart               ← AI service wrappers (quiz, assignment, etc.)
│   ├── gemini_service.dart     ← Direct Gemini AI integration
│   ├── logging_service.dart    ← Structured logging
│   ├── notification_service.dart ← Local notifications
│   ├── offline_cache_service.dart ← SharedPreferences TTL cache
│   ├── realtime/               ← Supabase Realtime subscriptions
│   └── storage_service.dart   ← File upload/download
│
└── shared/            ← Reusable widgets
    └── widgets/       ← AppButton, ShimmerLoader, EmptyState, etc.
```

### Authentication Flow
```
App Launch
    ↓
main.dart → SupabaseConfig.initialize()
    ↓
AuthNotifier._init() → auth.onAuthStateChange listener
    ↓
Session exists?
  YES → _loadProfile(userId)
           → fetch profiles + user_roles tables
           → AuthState(profile: ...) set
  NO  → AuthState() (empty)
    ↓
GoRouter redirect checks:
  isLoading → '/loading'
  !isAuthenticated → '/login'
  isAuthenticated + role=admin → '/admin'
  isAuthenticated + role=lecturer → '/lecturer'
  isAuthenticated + role=student → '/student'
```

### Role-Based Access Control
```
UserRole.student  → /student/*, /lecture/*, /assignment/*, /quiz/*, /session-*, /attendance, /gpa, /ranking, /timetable, /ai-tutor
UserRole.lecturer → /lecturer/*, /create-content, /grade-submission/*, /attendance-report, /lecturer-performance
UserRole.admin    → /admin/*, /analytics + all above routes

Protection via GoRouter redirect:
- /lecturer/* with student role → /student
- /admin/* with non-admin role → /lecturer or /student
```

### State Management Flow (Riverpod)
```
ProviderScope (root)
    ├── authProvider (StateNotifier) — auth state, profile
    ├── academicProvider (StateNotifier) — all academic data
    ├── sessionProvider (StateNotifier) — active session + timer
    ├── gameProvider (StateNotifier) — XP, badges, streaks
    ├── attendanceProvider (StateNotifier) — attendance records
    ├── gpaProvider (StateNotifier) — computed GPA
    ├── analyticsProvider (StateNotifier) — admin stats
    ├── themeModeProvider (StateNotifier) — dark/light
    ├── languageProvider (StateNotifier) — en/ur
    └── FutureProviders (autoDispose):
        ├── rankingProvider — leaderboard
        ├── timetableProvider — weekly schedule
        └── parentChildProvider — parent lookup
```

### Database Flow (Supabase)
```
Flutter App → Supabase Client (JWT authenticated)
    ↓
Row Level Security (RLS) checks role
    ↓
Tables: profiles, user_roles, courses, lectures, 
        assignments, submissions, quizzes, quiz_attempts,
        study_sessions, game_state, attendance, timetable,
        login_events, notifications
    ↓
Storage Buckets: avatars, lecture-files, assignment-files, submissions
    ↓
Realtime: attendance, study_sessions, notifications channels
```

### AI Flow (Gemini)
```
User Action (create quiz / assignment / ask tutor)
    ↓
GeminiService.instance (singleton)
    ↓
Prompt construction with _safe() sanitization
    ↓
GenerativeModel.generateContent() → Gemini 2.0 Flash API
    ↓
_retry() — up to 2 retries on failure
    ↓
JSON extraction → _parseList() or _parseMap()
    ↓
Dart model construction → returned to UI
```

### Face Detection Flow
```
session_active_screen.dart initState()
    ↓
availableCameras() → front camera selection
    ↓
CameraController.initialize() (ResolutionPreset.low)
    ↓
FaceDetector(FaceDetectorMode.fast) initialized
    ↓
Timer.periodic(6 seconds) → _runFaceDetection()
    ↓
takePicture() → InputImage.fromFilePath()
    ↓
faceDetector.processImage() → List<Face>
    ↓
Face analysis:
  - No face → violation
  - Eyes closed (< 0.3) → violation
  - Head yaw > 45° → violation
    ↓
3+ violations → session failed
0 violations → badges unlocked
    ↓
Temp photo file deleted immediately after processing
```

---

## 10. DEPENDENCY DOCUMENTATION

| Package | Purpose | Used In | Notes |
|---|---|---|---|
| `supabase_flutter` | Backend (auth, database, storage, realtime) | Everywhere | Core dependency |
| `flutter_riverpod` | State management | All providers + screens | Excellent for this scale |
| `go_router` | Navigation + deep linking + role guards | app_router.dart | Best routing package for Flutter |
| `google_generative_ai` | Gemini AI integration | gemini_service.dart | Powers all AI features |
| `camera` | Camera preview + capture | session_active_screen.dart | Android/iOS only |
| `google_mlkit_face_detection` | ML Kit face analysis | session_active_screen.dart | Offline, on-device |
| `file_picker` | Document/file selection | storage_service.dart | Cross-platform |
| `syncfusion_flutter_pdfviewer` | PDF rendering | lecture_detail_screen.dart | License required for production |
| `dio` | HTTP downloads with progress | storage_service.dart | Better than http package |
| `flutter_local_notifications` | Local push notifications | notification_service.dart | Android + iOS |
| `timezone` | Scheduled notifications | notification_service.dart | Required by flutter_local_notifications |
| `flutter_animate` | UI animations | Multiple screens | Lightweight, declarative |
| `cached_network_image` | Image caching | Profile screens | Prevents re-downloading |
| `shimmer` | Loading skeleton UI | shimmer_loader.dart | UX improvement |
| `fl_chart` | Charts and graphs | analytics_screen, gpa_screen | Well-maintained |
| `percent_indicator` | Circular/linear progress | attendance_screen | Simple and effective |
| `google_fonts` | Inter font | app_theme.dart | Brand font |
| `shared_preferences` | Simple key-value local storage | offline_cache_service.dart | Cross-platform |
| `sqflite` | SQLite local database | (available but not used yet) | For offline-first upgrade |
| `flutter_secure_storage` | Encrypted local storage | (available but not used yet) | For sensitive data |
| `intl` | Date/number formatting | Admin dashboard | Internationalization |
| `uuid` | UUID generation | storage_service.dart | Unique file names |
| `url_launcher` | Open URLs in browser | (available) | For external links |
| `permission_handler` | Runtime permissions | (used by camera implicitly) | Android/iOS |
| `connectivity_plus` | Network status | offline_cache_service.dart | Online/offline detection |
| `vibration` | Haptic feedback | session_active_screen.dart | Violation alerts |
| `device_info_plus` | Device information | auth_provider.dart | Login event tracking |
| `path_provider` | App file paths | storage_service.dart | Download directory |
| `open_filex` | Open downloaded files | lecture_detail_screen.dart | Cross-platform file opener |
| `image_picker` | Camera/gallery image pick | profile_screen.dart | Profile photo |
| `logging` | Structured app logging | logging_service.dart | Production-safe logging |
| `flutter_dotenv` | .env file loading | supabase_config.dart | Environment variables |

### ⚠️ Syncfusion License Note
`syncfusion_flutter_pdfviewer` is FREE for community use (revenue < $1M/year). For commercial apps, a license is required. See: https://syncfusion.com/products/communitylicense

---

## 11. ANDROID FILE DOCUMENTATION

### `AndroidManifest.xml`
**Purpose:** App registration with Android OS  
**Contains:** App permissions, activities, services, deep links, file providers  
**Critical entries:**
- `<uses-permission android:name="android.permission.CAMERA"/>` — Required for ML Kit face detection
- `<meta-data android:name="com.google.mlkit.vision.DEPENDENCIES" android:value="face"/>` — Downloads ML Kit face model on install
- `<provider>` FileProvider — Required for file_picker to share files between apps
- Supabase deep link: `io.supabase.studylock://` — Required for OAuth and password reset
**If removed:** App crashes immediately — Android won't know how to launch it

### `MainActivity.kt`
**Purpose:** Entry point of Android app  
**Why:** Flutter requires a native Android Activity to host the Flutter engine  
**V2 Embedding:** Extends `FlutterActivity` (NOT old `FlutterFragmentActivity`)  
**If removed:** Android build fails — no entry point

### `settings.gradle`
**Purpose:** Defines which modules to include in the build and plugin management  
**Critical:** `includeBuild("${flutterSdkPath}/packages/flutter_tools/gradle")` — loads Flutter's Gradle plugins  
**If removed:** Build fails — Gradle can't find Flutter plugins

### `app/build.gradle`
**Purpose:** App-level build configuration  
**Contains:** SDK versions, signing configs, dependencies, build types  
**Critical settings:**
- `coreLibraryDesugaringEnabled true` — allows Java 8+ APIs on Android 5+
- `multiDexEnabled true` — allows app to exceed 65,536 method limit
- `ndkVersion "27.0.12077973"` — required for ML Kit native code
**If misconfigured:** Build fails or app crashes on older Android versions

### `build.gradle` (root)
**Purpose:** Project-level build configuration  
**Contains:** AGP version, Kotlin version, repository sources  
**If removed:** Build fails — Gradle can't find Android Gradle Plugin

### `gradle.properties`
**Purpose:** Gradle build settings  
**Critical:** `android.useAndroidX=true` — required for all modern Flutter plugins  
**If removed:** Hundreds of dependency conflicts

### `gradle-wrapper.properties`
**Purpose:** Specifies which Gradle version to use  
**Current:** Gradle 8.10.2  
**If wrong version:** Build fails with incompatibility errors

---

## 12. FINAL RECOMMENDATIONS

### 🚨 IMMEDIATE (Before any git commit)
1. **Rotate API keys** — Supabase anon key + Gemini API key are exposed
2. **Run `git rm --cached .env`** if you've committed .env before

### 🔴 HIGH PRIORITY (Before user testing)
3. **Add app icon** — use flutter_launcher_icons
4. **Add splash screen** — use flutter_native_splash
5. **Create production keystore** for release signing
6. **Test on Redmi Note 13** — verify camera permission flow in MIUI

### 🟡 MEDIUM PRIORITY (Before Play Store)
7. **Fix ranking screen** N+1 query — use SQL join
8. **Add GPA reactive updates** — fix gpa_provider ref.read pattern
9. **Enable ProGuard** for release builds
10. **Add Privacy Policy** — required by Play Store
11. **Add network security config** for production

### 🟢 LOW PRIORITY (Enhancements)
12. **Add pagination** to academic_provider for large datasets
13. **Add offline quiz caching** using sqflite
14. **Implement token expiry handling** with session timeout dialog
15. **Add web responsive layout** using LayoutBuilder breakpoints

---

*Report generated: June 2026 | StudyLock V2 | 75 Dart files | 35 packages*
