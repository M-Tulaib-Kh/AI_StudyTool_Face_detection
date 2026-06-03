import '../services/gemini_service.dart';
import '../data/models/models.dart';

class AIRecommendationService {
  static AIRecommendationService? _instance;
  static AIRecommendationService get instance => _instance ??= AIRecommendationService._();
  AIRecommendationService._();

  /// Returns AI-generated study recommendations based on performance
  Future<String> getStudyRecommendations({
    required List<QuizAttempt> attempts,
    required List<Quiz> quizzes,
    required String studentName,
  }) async {
    if (attempts.isEmpty) {
      return 'Start taking quizzes to get personalised recommendations.';
    }

    final avgScore = attempts.fold<double>(0, (s, a) =>
      s + (a.totalMarks > 0 ? a.score / a.totalMarks * 100 : 0)) / attempts.length;

    final weakSubjects = <String>[];
    for (final attempt in attempts) {
      final quiz = quizzes.where((q) => q.id == attempt.quizId).firstOrNull;
      if (quiz != null && attempt.totalMarks > 0) {
        final pct = attempt.score / attempt.totalMarks * 100;
        if (pct < 60) weakSubjects.add(quiz.subject);
      }
    }

    final prompt = '''
Student: $studentName
Average score: ${avgScore.toStringAsFixed(1)}%
Weak subjects: ${weakSubjects.isEmpty ? 'None' : weakSubjects.join(', ')}
Provide 3 concise, actionable study recommendations.
''';

    final result = await GeminiService.instance.generateAssignment(
      subject: 'General',
      prompt: prompt,
    );
    return result.description.isNotEmpty ? result.description : result.instructions;
  }

  /// Returns suggested learning path
  Future<String> getLearningPath({
    required String subject,
    required double currentLevel,
  }) async {
    final level = currentLevel >= 80 ? 'advanced' : currentLevel >= 50 ? 'intermediate' : 'beginner';
    final result = await GeminiService.instance.generateAssignment(
      subject: subject,
      prompt: 'Create a 4-week learning path for a $level level student in $subject.',
    );
    return result.instructions;
  }

  /// Weak area detection from quiz attempts
  Map<String, double> detectWeakAreas(List<QuizAttempt> attempts, List<Quiz> quizzes) {
    final subjectScores = <String, List<double>>{};
    for (final attempt in attempts) {
      final quiz = quizzes.where((q) => q.id == attempt.quizId).firstOrNull;
      if (quiz == null || attempt.totalMarks == 0) continue;
      final pct = attempt.score / attempt.totalMarks * 100;
      subjectScores.putIfAbsent(quiz.subject, () => []).add(pct);
    }
    return {
      for (final entry in subjectScores.entries)
        entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
    };
  }
}
