import '../data/models/models.dart';
import '../services/gemini_service.dart';

class AIQuizService {
  static AIQuizService? _instance;
  static AIQuizService get instance => _instance ??= AIQuizService._();
  AIQuizService._();

  Future<List<QuizQuestion>> generateQuiz({
    required String subject,
    required String topic,
    required int questionCount,
    String difficulty = 'medium',
  }) async {
    final prompt = 'Topic: "$topic". Difficulty: $difficulty. Generate $questionCount unique MCQ questions.';
    return GeminiService.instance.generateQuiz(
      subject: subject,
      prompt: prompt,
      count: questionCount,
    );
  }

  Future<String> generateStudyTips({
    required String subject,
    required List<String> weakAreas,
  }) async {
    final result = await GeminiService.instance.generateAssignment(
      subject: subject,
      prompt: 'Provide 5 concise study tips for weak areas: ${weakAreas.join(", ")}',
    );
    return result.description;
  }

  Future<({int score, String feedback, List<Map<String, dynamic>> breakdown})> gradeQuiz({
    required List<QuizQuestion> questions,
    required Map<String, String> answers,
  }) => GeminiService.instance.gradeQuiz(questions: questions, studentAnswers: answers);
}
