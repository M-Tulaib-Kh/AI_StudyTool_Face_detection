import '../services/gemini_service.dart';

class AIAssignmentService {
  static AIAssignmentService? _instance;
  static AIAssignmentService get instance => _instance ??= AIAssignmentService._();
  AIAssignmentService._();

  Future<({String title, String description, String instructions})> generateAssignment({
    required String subject,
    required String topic,
    required int totalMarks,
    String difficulty = 'medium',
  }) async {
    final prompt = 'Topic: "$topic". Total marks: $totalMarks. Difficulty: $difficulty. Create a practical assignment.';
    return GeminiService.instance.generateAssignment(subject: subject, prompt: prompt);
  }

  Future<({int marks, String feedback})> gradeSubmission({
    required String assignmentTitle,
    required String submissionText,
    required int totalMarks,
  }) => GeminiService.instance.gradeSubmission(
        assignmentPrompt: assignmentTitle,
        submissionText: submissionText,
        totalMarks: totalMarks,
      );
}
