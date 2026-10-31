import '../services/ai_service.dart';
import '../data/models/models.dart';

class AIPerformanceService {
  static AIPerformanceService? _instance;
  static AIPerformanceService get instance => _instance ??= AIPerformanceService._();
  AIPerformanceService._();

  Future<String> analyzePerformance({
    required String studentName,
    required List<QuizAttempt> attempts,
    required List<Submission> submissions,
    required int studyStreakDays,
    required int totalStudyMinutes,
  }) async {
    final avgQuiz = attempts.isEmpty ? 0.0 : attempts.fold<double>(0, (s, a) =>
      s + (a.totalMarks > 0 ? a.score / a.totalMarks * 100 : 0)) / attempts.length;

    final submittedOnTime = submissions.where((s) => s.status == SubmissionStatus.submitted).length;

    final prompt = '''
Analyze this student's academic performance:
- Name: $studentName
- Quiz average: ${avgQuiz.toStringAsFixed(1)}%
- Quizzes taken: ${attempts.length}
- Assignments submitted: $submittedOnTime / ${submissions.length}
- Study streak: $studyStreakDays days
- Total study time: $totalStudyMinutes minutes

Provide: 1) Performance summary 2) Key strengths 3) Areas to improve
Keep response concise and encouraging.
''';

    final result = await AiService.instance.generateAssignment(
      subject: 'Performance Analysis',
      prompt: prompt,
    );
    return result.description.isNotEmpty ? result.description : 'Analysis unavailable. Try again later.';
  }
}
