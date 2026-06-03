// ============================================================
// StudyLock — GPA Provider (Fixed: reactive ref.watch pattern)
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/gpa_model.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';

class GPAState {
  final GPASummary? summary;
  final bool isLoading;
  final String? error;

  const GPAState({this.summary, this.isLoading = false, this.error});

  GPAState copyWith({GPASummary? summary, bool? isLoading, String? error}) =>
      GPAState(
        summary: summary ?? this.summary,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

// Use a computed Provider instead of StateNotifier so it reacts to
// academicProvider changes automatically via ref.watch
final gpaProvider = Provider<GPAState>((ref) {
  final academic = ref.watch(academicProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return const GPAState();
  if (academic.isLoading) return const GPAState(isLoading: true);

  try {
    final attempts =
        academic.attempts.where((a) => a.studentId == user.id).toList();
    final quizzes = academic.quizzes;
    final courses = academic.courses;

    // Group attempts by course
    final courseMap = <String, List<double>>{};
    for (final attempt in attempts) {
      final quiz =
          quizzes.where((q) => q.id == attempt.quizId).firstOrNull;
      if (quiz == null) continue;
      final courseId = quiz.courseId ?? 'general';
      courseMap.putIfAbsent(courseId, () => []);
      if (attempt.totalMarks > 0) {
        courseMap[courseId]!.add(attempt.score / attempt.totalMarks * 100);
      }
    }

    final courseGrades = courseMap.entries.map((entry) {
      final course =
          courses.where((c) => c.id == entry.key).firstOrNull;
      final avgPct = entry.value.isEmpty
          ? 0.0
          : entry.value.reduce((a, b) => a + b) / entry.value.length;
      return CourseGrade(
        courseId: entry.key,
        courseName: course?.title ?? 'Course',
        subject: course?.subject ?? '',
        creditHours: 3,
        grade: LetterGradeX.fromMarks(avgPct),
        marks: avgPct * 3 / 100,
        totalMarks: 3,
        semester: 1,
      );
    }).toList();

    if (courseGrades.isEmpty) return const GPAState();

    final semGPA = SemesterGPA(semester: 1, courses: courseGrades);
    return GPAState(summary: GPASummary(semesters: [semGPA]));
  } catch (e) {
    return GPAState(error: e.toString());
  }
});
