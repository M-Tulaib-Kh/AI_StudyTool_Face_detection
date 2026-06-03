import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../data/models/models.dart';

class AcademicState {
  final List<Course> courses;
  final List<Lecture> lectures;
  final List<Assignment> assignments;
  final List<Submission> submissions;
  final List<Quiz> quizzes;
  final List<QuizAttempt> attempts;
  final bool isLoading;
  final String? error;
  const AcademicState({
    this.courses = const [],
    this.lectures = const [],
    this.assignments = const [],
    this.submissions = const [],
    this.quizzes = const [],
    this.attempts = const [],
    this.isLoading = false,
    this.error,
  });
  AcademicState copyWith({
    List<Course>? courses,
    List<Lecture>? lectures,
    List<Assignment>? assignments,
    List<Submission>? submissions,
    List<Quiz>? quizzes,
    List<QuizAttempt>? attempts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AcademicState(
        courses: courses ?? this.courses,
        lectures: lectures ?? this.lectures,
        assignments: assignments ?? this.assignments,
        submissions: submissions ?? this.submissions,
        quizzes: quizzes ?? this.quizzes,
        attempts: attempts ?? this.attempts,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AcademicNotifier extends StateNotifier<AcademicState> {
  AcademicNotifier() : super(const AcademicState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      final futures = <Future>[
        SupabaseConfig.client
            .from('courses')
            .select()
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('lectures')
            .select()
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .from('assignments')
            .select()
            .order('deadline', ascending: true),
        SupabaseConfig.client
            .from('quizzes')
            .select()
            .order('created_at', ascending: false),
        if (uid != null)
          SupabaseConfig.client
              .from('submissions')
              .select()
              .eq('student_id', uid),
        if (uid != null)
          SupabaseConfig.client
              .from('quiz_attempts')
              .select()
              .eq('student_id', uid),
      ];
      final r = await Future.wait(futures);
      state = state.copyWith(
        isLoading: false,
        courses: (r[0] as List).map((j) => Course.fromJson(j)).toList(),
        lectures: (r[1] as List).map((j) => Lecture.fromJson(j)).toList(),
        assignments: (r[2] as List).map((j) => Assignment.fromJson(j)).toList(),
        quizzes: (r[3] as List).map((j) => Quiz.fromJson(j)).toList(),
        submissions: uid != null
            ? (r[4] as List).map((j) => Submission.fromJson(j)).toList()
            : [],
        attempts: uid != null
            ? (r[5] as List).map((j) => QuizAttempt.fromJson(j)).toList()
            : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> incrementLectureView(String id) async {
    try {
      final l = state.lectures.where((x) => x.id == id).firstOrNull;
      if (l == null) return;
      await SupabaseConfig.client
          .from('lectures')
          .update({'views': l.views + 1}).eq('id', id);
    } catch (_) {}
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String fileUrl,
    required String fileName,
  }) async {
    await SupabaseConfig.client.from('submissions').upsert({
      'assignment_id': assignmentId,
      'student_id': studentId,
      'student_name': studentName,
      'file_url': fileUrl,
      'file_name': fileName,
      'submitted_at': DateTime.now().toIso8601String(),
      'status': 'submitted',
    });
    await loadAll();
  }

  Future<QuizAttempt> submitQuizAttempt({
    required String quizId,
    required String studentId,
    required String studentName,
    required Map<String, String> answers,
    required int score,
    required int totalMarks,
  }) async {
    final data = await SupabaseConfig.client
        .from('quiz_attempts')
        .insert({
          'quiz_id': quizId,
          'student_id': studentId,
          'student_name': studentName,
          'answers': answers,
          'score': score,
          'total_marks': totalMarks,
          'status': 'submitted',
        })
        .select()
        .single();
    await loadAll();
    // ignore: unnecessary_cast
    return QuizAttempt.fromJson(data as Map<String, dynamic>);
  }

  Future<void> gradeSubmission({
    required String submissionId,
    required int marks,
    required String feedback,
    required String gradedById,
  }) async {
    await SupabaseConfig.client.from('submissions').update({
      'marks_obtained': marks,
      'feedback': feedback,
      'graded_by': gradedById,
      'graded_at': DateTime.now().toIso8601String(),
      'status': 'graded',
    }).eq('id', submissionId);
    await loadAll();
  }

  Future<void> createCourse(
      {required String title,
      required String description,
      required String subject,
      required String lecturerId,
      required String lecturerName}) async {
    await SupabaseConfig.client.from('courses').insert({
      'title': title,
      'description': description,
      'subject': subject,
      'lecturer_id': lecturerId,
      'lecturer_name': lecturerName,
    });
    await loadAll();
  }

  Future<void> createLecture(
      {required String courseId,
      required String title,
      required String subject,
      required String description,
      required String fileUrl,
      required String fileName,
      required String uploadedBy}) async {
    await SupabaseConfig.client.from('lectures').insert({
      'course_id': courseId,
      'title': title,
      'subject': subject,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'uploaded_by': uploadedBy,
    });
    await loadAll();
  }

  Future<void> createAssignment(
      {required String courseId,
      required String title,
      required String subject,
      required String description,
      required String instructions,
      required DateTime deadline,
      required int totalMarks,
      required String createdBy,
      required bool aiGenerated,
      String fileUrl = '',
      String fileName = ''}) async {
    await SupabaseConfig.client.from('assignments').insert({
      'course_id': courseId,
      'title': title,
      'subject': subject,
      'description': description,
      'instructions': instructions,
      'deadline': deadline.toIso8601String(),
      'total_marks': totalMarks,
      'created_by': createdBy,
      'ai_generated': aiGenerated,
      'file_url': fileUrl,
      'file_name': fileName,
    });
    await loadAll();
  }

  Future<void> createQuiz(
      {required String courseId,
      required String title,
      required String subject,
      required String description,
      required List<QuizQuestion> questions,
      required int durationMinutes,
      required String createdBy,
      required bool aiGenerated,
      DateTime? deadline}) async {
    await SupabaseConfig.client.from('quizzes').insert({
      'course_id': courseId,
      'title': title,
      'subject': subject,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'duration_minutes': durationMinutes,
      'total_marks': questions.fold(0, (a, q) => a + q.marks),
      'created_by': createdBy,
      'ai_generated': aiGenerated,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
    });
    await loadAll();
  }

  // Lecturer: get submissions for their assignments
  Future<List<Submission>> getSubmissionsForLecturer(String lecturerId) async {
    final courses = state.courses
        .where((c) => c.lecturerId == lecturerId)
        .map((c) => c.id)
        .toList();
    if (courses.isEmpty) return [];
    final assignIds = state.assignments
        .where((a) => courses.contains(a.courseId))
        .map((a) => a.id)
        .toList();
    if (assignIds.isEmpty) return [];
    final data = await SupabaseConfig.client
        .from('submissions')
        .select()
        .inFilter('assignment_id', assignIds);
    return (data as List).map((j) => Submission.fromJson(j)).toList();
  }
}

final academicProvider = StateNotifierProvider<AcademicNotifier, AcademicState>(
    (ref) => AcademicNotifier());
