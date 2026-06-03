import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/models.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/student/screens/student_shell.dart';
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/screens/academic_screen.dart';
import '../../features/student/screens/rewards_screen.dart';
import '../../features/student/screens/profile_screen.dart';
import '../../features/student/screens/lecture_detail_screen.dart';
import '../../features/student/screens/assignment_detail_screen.dart';
import '../../features/student/screens/quiz_attempt_screen.dart';
import '../../features/student/screens/quiz_result_screen.dart';
import '../../features/session/screens/session_setup_screen.dart';
import '../../features/session/screens/session_active_screen.dart';
import '../../features/session/screens/session_result_screen.dart';
import '../../features/lecturer/screens/lecturer_shell.dart';
import '../../features/lecturer/screens/lecturer_home_screen.dart';
import '../../features/lecturer/screens/manage_screen.dart';
import '../../features/lecturer/screens/create_content_screen.dart';
import '../../features/lecturer/screens/grade_submission_screen.dart';
import '../../features/lecturer/screens/lecturer_performance_screen.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_courses_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/attendance/screens/attendance_report_screen.dart';
import '../../features/gpa/screens/gpa_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/ranking/screens/ranking_screen.dart';
import '../../features/timetable/screens/timetable_screen.dart';
import '../../features/ai_tutor/screens/ai_tutor_screen.dart';
import '../../features/parent/screens/parent_portal_screen.dart';
import '../../shared/widgets/loading_screen.dart';
import '../../shared/widgets/not_found_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _studentKey = GlobalKey<NavigatorState>(debugLabel: 'student');
final _lecturerKey = GlobalKey<NavigatorState>(debugLabel: 'lecturer');
final _adminKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/loading',
    refreshListenable: notifier,
    errorBuilder: (_, state) => NotFoundScreen(error: state.error.toString()),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading) return loc == '/loading' ? null : '/loading';
      const pub = ['/loading', '/onboarding', '/login', '/register', '/forgot-password'];
      if (!auth.isAuthenticated && !pub.contains(loc)) return '/login';
      if (auth.isAuthenticated && pub.contains(loc)) {
        return switch (auth.role) {
          UserRole.admin => '/admin',
          UserRole.lecturer => '/lecturer',
          UserRole.student => '/student',
        };
      }
      if (auth.isAuthenticated) {
        if (loc.startsWith('/lecturer') && auth.role == UserRole.student) return '/student';
        if (loc.startsWith('/admin') && auth.role != UserRole.admin) {
          return auth.role == UserRole.lecturer ? '/lecturer' : '/student';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ── Student shell ──────────────────────────────────────
      ShellRoute(
        navigatorKey: _studentKey,
        builder: (_, __, child) => StudentShell(child: child),
        routes: [
          GoRoute(path: '/student', builder: (_, __) => const StudentHomeScreen()),
          GoRoute(path: '/student/academic', builder: (_, __) => const AcademicScreen()),
          GoRoute(path: '/student/session', builder: (_, __) => const SessionSetupScreen()),
          GoRoute(path: '/student/rewards', builder: (_, __) => const RewardsScreen()),
          GoRoute(path: '/student/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Student standalone routes ──────────────────────────
      GoRoute(path: '/lecture/:id', builder: (_, s) => LectureDetailScreen(lectureId: s.pathParameters['id']!)),
      GoRoute(path: '/assignment/:id', builder: (_, s) => AssignmentDetailScreen(assignmentId: s.pathParameters['id']!)),
      GoRoute(path: '/quiz/:id', builder: (_, s) => QuizAttemptScreen(quizId: s.pathParameters['id']!)),
      GoRoute(path: '/quiz-result/:attemptId', builder: (_, s) => QuizResultScreen(attemptId: s.pathParameters['attemptId']!)),
      GoRoute(path: '/session-active', builder: (_, __) => const SessionActiveScreen()),
      GoRoute(
        path: '/session-result',
        builder: (_, s) => SessionResultScreen(
          status: s.uri.queryParameters['status'] ?? 'completed',
          durationSeconds: int.tryParse(s.uri.queryParameters['duration'] ?? '0') ?? 0,
          violations: int.tryParse(s.uri.queryParameters['violations'] ?? '0') ?? 0,
          pointsEarned: int.tryParse(s.uri.queryParameters['points'] ?? '0') ?? 0,
        ),
      ),

      // ── Phase 2+ routes ────────────────────────────────────
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/attendance-report', builder: (_, __) => const AttendanceReportScreen()),
      GoRoute(path: '/gpa', builder: (_, __) => const GPAScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/ranking', builder: (_, __) => const RankingScreen()),
      GoRoute(path: '/timetable', builder: (_, __) => const TimetableScreen()),
      GoRoute(path: '/ai-tutor', builder: (_, __) => const AITutorScreen()),
      GoRoute(path: '/parent-portal', builder: (_, __) => const ParentPortalScreen()),
      GoRoute(path: '/lecturer-performance', builder: (_, __) => const LecturerPerformanceScreen()),

      // ── Lecturer shell ─────────────────────────────────────
      ShellRoute(
        navigatorKey: _lecturerKey,
        builder: (_, __, child) => LecturerShell(child: child),
        routes: [
          GoRoute(path: '/lecturer', builder: (_, __) => const LecturerHomeScreen()),
          GoRoute(path: '/lecturer/manage', builder: (_, __) => const ManageScreen()),
          GoRoute(path: '/lecturer/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/create-content', builder: (_, s) => CreateContentScreen(type: s.uri.queryParameters['type'] ?? 'lecture')),
      GoRoute(path: '/grade-submission/:id', builder: (_, s) => GradeSubmissionScreen(submissionId: s.pathParameters['id']!)),

      // ── Admin shell ────────────────────────────────────────
      ShellRoute(
        navigatorKey: _adminKey,
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
          GoRoute(path: '/admin/courses', builder: (_, __) => const AdminCoursesScreen()),
        ],
      ),

      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
