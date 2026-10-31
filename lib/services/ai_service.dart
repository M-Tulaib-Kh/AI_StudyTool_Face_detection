import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';

/// Talks to the `ai-proxy` Supabase Edge Function (Groq on the server side).
/// No AI provider key is ever stored in or shipped with the app.
class AiService {
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();
  AiService._();

  static const _function = 'ai-proxy';
  static const _maxRetries = 2;

  Future<List<QuizQuestion>> generateQuiz({
    required String subject,
    required String prompt,
    required int count,
  }) async {
    final text = await _invoke('quiz', {'subject': subject, 'prompt': prompt, 'count': count});
    final list = _parseList(text);
    return list.asMap().entries.map((e) {
      final j = Map<String, dynamic>.from(e.value as Map);
      j['id'] = j['id']?.toString().isNotEmpty == true ? j['id'] : 'q${e.key + 1}';
      return QuizQuestion.fromJson(j);
    }).toList();
  }

  Future<({String title, String description, String instructions})> generateAssignment({
    required String subject,
    required String prompt,
  }) async {
    final text = await _invoke('assignment', {'subject': subject, 'prompt': prompt});
    final j = _parseMap(text);
    return (
      title: j['title'] as String? ?? 'Assignment',
      description: j['description'] as String? ?? '',
      instructions: j['instructions'] as String? ?? '',
    );
  }

  Future<({int score, String feedback, List<Map<String, dynamic>> breakdown})> gradeQuiz({
    required List<QuizQuestion> questions,
    required Map<String, String> studentAnswers,
  }) async {
    final text = await _invoke('grade_quiz', {
      'questions': questions.map((q) => q.toJson()).toList(),
      'answers': studentAnswers,
    });
    final j = _parseMap(text);
    return (
      score: (j['score'] as num?)?.toInt() ?? 0,
      feedback: j['feedback'] as String? ?? '',
      breakdown: (j['breakdown'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Future<({int marks, String feedback})> gradeSubmission({
    required String assignmentPrompt,
    required String submissionText,
    required int totalMarks,
  }) async {
    final text = await _invoke('grade_submission', {
      'assignmentPrompt': assignmentPrompt,
      'submissionText': submissionText,
      'totalMarks': totalMarks,
    });
    final j = _parseMap(text);
    final marks = ((j['marks'] as num?)?.toInt() ?? 0).clamp(0, totalMarks);
    return (marks: marks, feedback: j['feedback'] as String? ?? '');
  }

  // ── Transport ────────────────────────────────────────────────

  Future<String> _invoke(String task, Map<String, dynamic> params) async {
    Object? last;
    for (var i = 0; i <= _maxRetries; i++) {
      try {
        final res = await Supabase.instance.client.functions
            .invoke(_function, body: {'task': task, 'params': params});
        final data = res.data;
        final content = data is Map ? data['content'] : null;
        if (content is String && content.isNotEmpty) return content;
        throw const FormatException('Empty AI response');
      } on FunctionException catch (e) {
        // Do not retry client errors (auth, validation, rate limit, forbidden).
        if (e.status >= 400 && e.status < 500) {
          throw Exception(_friendly(e.status));
        }
        last = e;
      } catch (e) {
        last = e;
      }
      if (i < _maxRetries) await Future.delayed(Duration(seconds: i + 1));
    }
    throw Exception('AI is temporarily unavailable. Please try again. ($last)');
  }

  String _friendly(int status) => switch (status) {
        401 => 'Please sign in again.',
        403 => 'You are not allowed to use this AI feature.',
        429 => 'AI usage limit reached. Please try again later.',
        _ => 'The AI request was rejected.',
      };

  // ── Parsing ──────────────────────────────────────────────────

  String _extractJson(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final fArr = cleaned.indexOf('[');
    final fObj = cleaned.indexOf('{');
    final lArr = cleaned.lastIndexOf(']');
    final lObj = cleaned.lastIndexOf('}');
    int s = -1, e = -1;
    if (fArr != -1 && (fObj == -1 || fArr < fObj)) {
      s = fArr;
      e = lArr;
    } else if (fObj != -1) {
      s = fObj;
      e = lObj;
    }
    if (s == -1 || e == -1 || e < s) throw const FormatException('No JSON found');
    return cleaned.substring(s, e + 1);
  }

  List<dynamic> _parseList(String t) {
    try {
      final d = jsonDecode(_extractJson(t));
      if (d is List) return d;
      if (d is Map && d['questions'] is List) return d['questions'] as List;
      throw const FormatException('Expected array');
    } catch (e) {
      throw Exception('Invalid AI array response: $e');
    }
  }

  Map<String, dynamic> _parseMap(String t) {
    try {
      final d = jsonDecode(_extractJson(t));
      if (d is Map) return Map<String, dynamic>.from(d);
      throw const FormatException('Expected object');
    } catch (e) {
      throw Exception('Invalid AI object response: $e');
    }
  }
}
