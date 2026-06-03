import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../data/models/attendance_model.dart';

class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? error;

  const AttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AttendanceState(
        records: records ?? this.records,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );

  /// Summaries per course for a specific student
  List<AttendanceSummary> summariesForStudent(
      String studentId, Map<String, String> courseNames) {
    final courseIds = records
        .where((r) => r.studentId == studentId)
        .map((r) => r.courseId)
        .toSet();
    return courseIds
        .map((cid) => AttendanceSummary.fromRecords(
              studentId,
              cid,
              courseNames[cid] ?? 'Unknown',
              records,
            ))
        .toList();
  }

  double overallPercentage(String studentId) {
    final myRecords = records.where((r) => r.studentId == studentId).toList();
    if (myRecords.isEmpty) return 0.0;
    final present = myRecords
        .where((r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.late)
        .length;
    return (present / myRecords.length * 100).clamp(0, 100);
  }

  /// Monthly breakdown for student
  Map<String, int> monthlyPresent(String studentId) {
    final result = <String, int>{};
    for (final r in records.where((r) => r.studentId == studentId)) {
      final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      if (r.status == AttendanceStatus.present ||
          r.status == AttendanceStatus.late) {
        result[key] = (result[key] ?? 0) + 1;
      }
    }
    return result;
  }

  /// Attendance records for a specific student
  List<AttendanceRecord> forStudent(String studentId) =>
      records.where((r) => r.studentId == studentId).toList();
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final data = await SupabaseConfig.client
          .from('attendance')
          .select()
          .order('date', ascending: false);

      final records =
          (data as List).map((j) => AttendanceRecord.fromJson(j)).toList();
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Lecturer marks attendance for multiple students
  Future<void> markBulkAttendance({
    required String courseId,
    required String lecturerId,
    required DateTime date,
    required Map<String, AttendanceStatus> studentStatuses,
    required Map<String, String> studentNames,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      // Upsert attendance records
      final records = studentStatuses.entries
          .map((e) => {
                'course_id': courseId,
                'student_id': e.key,
                'student_name': studentNames[e.key] ?? '',
                'lecturer_id': lecturerId,
                'status': e.value.value,
                'date': dateStr,
              })
          .toList();

      await SupabaseConfig.client
          .from('attendance')
          .upsert(records, onConflict: 'course_id,student_id,date');
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Mark single student attendance
  Future<void> markAttendance({
    required String courseId,
    required String studentId,
    required String studentName,
    required String lecturerId,
    required AttendanceStatus status,
    required DateTime date,
    String? remarks,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      await SupabaseConfig.client.from('attendance').upsert({
        'course_id': courseId,
        'student_id': studentId,
        'student_name': studentName,
        'lecturer_id': lecturerId,
        'status': status.value,
        'date': dateStr,
        if (remarks != null) 'remarks': remarks,
      }, onConflict: 'course_id,student_id,date');
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get attendance for a specific course
  List<AttendanceRecord> forCourse(String courseId) =>
      state.records.where((r) => r.courseId == courseId).toList();

  /// Get attendance for a specific student
  List<AttendanceRecord> forStudent(String studentId) =>
      state.records.where((r) => r.studentId == studentId).toList();
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>(
  (ref) => AttendanceNotifier(),
);
