import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
// ignore: unused_import
import '../data/models/models.dart';

class AnalyticsData {
  final int totalStudents;
  final int totalLecturers;
  final int totalCourses;
  final int totalLectures;
  final int totalAssignments;
  final int totalQuizzes;
  final int totalSubmissions;
  final int totalQuizAttempts;
  final double avgQuizScore;
  final List<Map<String, dynamic>> departmentStats;
  final List<Map<String, dynamic>> recentActivity;
  final List<Map<String, dynamic>> topStudents;
  final Map<String, int> weeklyActivity;

  const AnalyticsData({
    this.totalStudents = 0,
    this.totalLecturers = 0,
    this.totalCourses = 0,
    this.totalLectures = 0,
    this.totalAssignments = 0,
    this.totalQuizzes = 0,
    this.totalSubmissions = 0,
    this.totalQuizAttempts = 0,
    this.avgQuizScore = 0,
    this.departmentStats = const [],
    this.recentActivity = const [],
    this.topStudents = const [],
    this.weeklyActivity = const {},
  });
}

class AnalyticsState {
  final AnalyticsData data;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.data = const AnalyticsData(),
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith(
          {AnalyticsData? data, bool? isLoading, String? error}) =>
      AnalyticsState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(const AnalyticsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('profiles')
            .select('id, department')
            .limit(1000),
        SupabaseConfig.client.from('user_roles').select('role').limit(1000),
        SupabaseConfig.client.from('courses').select('id').limit(1000),
        SupabaseConfig.client.from('lectures').select('id').limit(1000),
        SupabaseConfig.client.from('assignments').select('id').limit(1000),
        SupabaseConfig.client.from('quizzes').select('id').limit(1000),
        SupabaseConfig.client.from('submissions').select('id').limit(1000),
        SupabaseConfig.client
            .from('quiz_attempts')
            .select('score, total_marks')
            .limit(1000),
      ]);

      final roles = results[1] as List;
      final students = roles.where((r) => r['role'] == 'student').length;
      final lecturers = roles.where((r) => r['role'] == 'lecturer').length;

      final attempts = results[7] as List;
      final avgScore = attempts.isEmpty
          ? 0.0
          : attempts.fold<double>(0, (s, a) {
                final total = (a['total_marks'] as num?)?.toDouble() ?? 0;
                final score = (a['score'] as num?)?.toDouble() ?? 0;
                return s + (total > 0 ? score / total * 100 : 0);
              }) /
              attempts.length;

      // Department stats from profiles
      final profiles = results[0] as List;
      final deptMap = <String, int>{};
      for (final p in profiles) {
        final dept = p['department'] as String? ?? 'Unknown';
        deptMap[dept] = (deptMap[dept] ?? 0) + 1;
      }
      final deptStats = deptMap.entries
          .map((e) => {'department': e.key, 'count': e.value})
          .toList();

      state = state.copyWith(
        isLoading: false,
        data: AnalyticsData(
          totalStudents: students,
          totalLecturers: lecturers,
          totalCourses: (results[2] as List).length,
          totalLectures: (results[3] as List).length,
          totalAssignments: (results[4] as List).length,
          totalQuizzes: (results[5] as List).length,
          totalSubmissions: (results[6] as List).length,
          totalQuizAttempts: attempts.length,
          avgQuizScore: avgScore,
          departmentStats: deptStats,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(),
);
