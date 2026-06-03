import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config/supabase_config.dart' show AppEnv;
import '../data/models/models.dart';

class GeminiService {
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();
  GeminiService._();

  static const _model = 'gemini-2.0-flash';
  static const _maxRetries = 2;
  late final GenerativeModel _gemini = GenerativeModel(model: _model, apiKey: AppEnv.geminiApiKey);

  Future<List<QuizQuestion>> generateQuiz({required String subject, required String prompt, required int count}) async {
    final p = '''You are an academic quiz generator for subject: "${_safe(subject)}".
Generate exactly $count MCQ questions about: "${_safe(prompt)}".
Return ONLY valid JSON array, no markdown:
[{"id":"q1","questionText":"...","optionA":"...","optionB":"...","optionC":"...","optionD":"...","correctAnswer":"A","marks":2}]''';
    return _retry(() async {
      final r = await _gemini.generateContent([Content.text(p)]);
      final list = _parseList(r.text ?? '');
      return list.asMap().entries.map((e) {
        final j = Map<String, dynamic>.from(e.value as Map);
        j['id'] = j['id']?.toString().isNotEmpty == true ? j['id'] : 'q${e.key + 1}';
        return QuizQuestion.fromJson(j);
      }).toList();
    });
  }

  Future<({String title, String description, String instructions})> generateAssignment({required String subject, required String prompt}) async {
    final p = '''Academic assignment creator. Subject: "${_safe(subject)}". Request: "${_safe(prompt)}".
Return ONLY valid JSON object, no markdown:
{"title":"...","description":"...","instructions":"..."}''';
    return _retry(() async {
      final r = await _gemini.generateContent([Content.text(p)]);
      final j = _parseMap(r.text ?? '');
      return (title: j['title'] as String? ?? 'Assignment', description: j['description'] as String? ?? '', instructions: j['instructions'] as String? ?? '');
    });
  }

  Future<({int score, String feedback, List<Map<String, dynamic>> breakdown})> gradeQuiz({required List<QuizQuestion> questions, required Map<String, String> studentAnswers}) async {
    final p = '''Grade this quiz. Questions: ${jsonEncode(questions.map((q) => q.toJson()).toList())}. Answers: ${jsonEncode(studentAnswers)}.
Return ONLY valid JSON, no markdown:
{"score":0,"feedback":"...","breakdown":[{"questionId":"q1","correct":true,"studentAnswer":"A","correctAnswer":"A","explanation":"..."}]}''';
    return _retry(() async {
      final r = await _gemini.generateContent([Content.text(p)]);
      final j = _parseMap(r.text ?? '');
      return (score: (j['score'] as num?)?.toInt() ?? 0, feedback: j['feedback'] as String? ?? '',
          breakdown: (j['breakdown'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    });
  }

  Future<({int marks, String feedback})> gradeSubmission({required String assignmentPrompt, required String submissionText, required int totalMarks}) async {
    final p = '''Grade this submission. Assignment: "${_safe(assignmentPrompt)}". Total marks: $totalMarks. Submission: "${_safe(submissionText, 2000)}".
Return ONLY valid JSON, no markdown:
{"marks":0,"feedback":"..."}''';
    return _retry(() async {
      final r = await _gemini.generateContent([Content.text(p)]);
      final j = _parseMap(r.text ?? '');
      final marks = ((j['marks'] as num?)?.toInt() ?? 0).clamp(0, totalMarks);
      return (marks: marks, feedback: j['feedback'] as String? ?? '');
    });
  }

  Future<T> _retry<T>(Future<T> Function() fn) async {
    Object? last;
    for (int i = 0; i <= _maxRetries; i++) {
      try { return await fn(); } catch (e) { last = e; if (i < _maxRetries) await Future.delayed(Duration(seconds: i + 1)); }
    }
    throw Exception('AI failed after $_maxRetries retries: $last');
  }

  String _extractJson(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final fArr = cleaned.indexOf('['); final fObj = cleaned.indexOf('{');
    final lArr = cleaned.lastIndexOf(']'); final lObj = cleaned.lastIndexOf('}');
    int s = -1, e = -1;
    if (fArr != -1 && (fObj == -1 || fArr < fObj)) { s = fArr; e = lArr; }
    else if (fObj != -1) { s = fObj; e = lObj; }
    if (s == -1 || e == -1) throw const FormatException('No JSON found');
    return cleaned.substring(s, e + 1);
  }

  List<dynamic> _parseList(String t) {
    try { final d = jsonDecode(_extractJson(t)); if (d is List) return d; throw const FormatException('Expected array'); }
    catch (e) { throw Exception('Invalid AI array response: $e'); }
  }

  Map<String, dynamic> _parseMap(String t) {
    try { final d = jsonDecode(_extractJson(t)); if (d is Map) return Map<String, dynamic>.from(d); throw const FormatException('Expected object'); }
    catch (e) { throw Exception('Invalid AI object response: $e'); }
  }

  String _safe(String input, [int max = 500]) => input
      .replaceAll(RegExp(r'[<>{}\[\]]'), '')
      .replaceAll(RegExp(r'(ignore|forget|disregard).{0,30}(instruction|rule)', caseSensitive: false), '')
      .trim()
      .substring(0, input.length.clamp(0, max));
}
