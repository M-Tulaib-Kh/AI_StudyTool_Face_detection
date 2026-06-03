// ============================================================
// StudyLock — Attendance Models
// ============================================================

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get value => name;
  String get label => switch (this) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.late => 'Late',
    AttendanceStatus.excused => 'Excused',
  };
  static AttendanceStatus from(String s) =>
      AttendanceStatus.values.firstWhere((e) => e.name == s,
          orElse: () => AttendanceStatus.absent);
}

class AttendanceRecord {
  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final String? lecturerId;
  final AttendanceStatus status;
  final DateTime date;
  final String? remarks;
  final DateTime createdAt;

  const AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    this.lecturerId,
    required this.status,
    required this.date,
    this.remarks,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
    id: j['id'] as String,
    courseId: j['course_id'] as String,
    studentId: j['student_id'] as String,
    studentName: j['student_name'] as String? ?? '',
    lecturerId: j['lecturer_id'] as String?,
    status: AttendanceStatusX.from(j['status'] as String? ?? 'absent'),
    date: DateTime.parse(j['date'] as String),
    remarks: j['remarks'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'course_id': courseId,
    'student_id': studentId,
    'student_name': studentName,
    'lecturer_id': lecturerId,
    'status': status.value,
    'date': date.toIso8601String().split('T')[0],
    if (remarks != null) 'remarks': remarks,
  };
}

class AttendanceSummary {
  final String studentId;
  final String courseId;
  final String courseName;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;

  const AttendanceSummary({
    required this.studentId,
    required this.courseId,
    required this.courseName,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
  });

  double get percentage {
    if (totalClasses == 0) return 0.0;
    return ((presentCount + lateCount) / totalClasses * 100).clamp(0, 100);
  }

  String get status {
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'At Risk';
    return 'Critical';
  }

  factory AttendanceSummary.fromRecords(
    String studentId, String courseId, String courseName,
    List<AttendanceRecord> records,
  ) {
    final courseRecords = records.where((r) => r.courseId == courseId && r.studentId == studentId).toList();
    return AttendanceSummary(
      studentId: studentId,
      courseId: courseId,
      courseName: courseName,
      totalClasses: courseRecords.length,
      presentCount: courseRecords.where((r) => r.status == AttendanceStatus.present).length,
      absentCount: courseRecords.where((r) => r.status == AttendanceStatus.absent).length,
      lateCount: courseRecords.where((r) => r.status == AttendanceStatus.late).length,
      excusedCount: courseRecords.where((r) => r.status == AttendanceStatus.excused).length,
    );
  }
}
