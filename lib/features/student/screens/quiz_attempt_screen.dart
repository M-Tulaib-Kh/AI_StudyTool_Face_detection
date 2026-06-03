import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
// ignore: unused_import
import '../../../data/models/models.dart';
import '../../../services/gemini_service.dart';
import '../../../shared/widgets/app_button.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizAttemptScreen({super.key, required this.quizId});
  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  int _current = 0;
  final Map<String, String> _answers = {};
  int _remaining = 0;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quiz = ref
          .read(academicProvider)
          .quizzes
          .where((q) => q.id == widget.quizId)
          .firstOrNull;
      if (quiz != null) {
        setState(() => _remaining = quiz.durationMinutes * 60);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_remaining <= 0) {
            _timer?.cancel();
            _submit();
          } else
            setState(() => _remaining--);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final quiz = ref
        .read(academicProvider)
        .quizzes
        .where((q) => q.id == widget.quizId)
        .firstOrNull;
    final user = ref.read(currentUserProvider);
    if (quiz == null || user == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      int score = 0;
      for (final q in quiz.questions) {
        if (_answers[q.id] == q.correctAnswer) score += q.marks;
      }
      final attempt = await ref
          .read(academicProvider.notifier)
          .submitQuizAttempt(
              quizId: quiz.id,
              studentId: user.id,
              studentName: user.fullName,
              answers: _answers,
              score: score,
              totalMarks: quiz.totalMarks);
      // AI grade in background
      GeminiService.instance
          .gradeQuiz(questions: quiz.questions, studentAnswers: _answers)
          .then((result) {
        ref
            .read(academicProvider)
            .attempts
            .where((a) => a.id == attempt.id)
            .firstOrNull;
      }).ignore();
      if (mounted) context.go('/quiz-result/${attempt.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Submit failed: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);
    final quiz = state.quizzes.where((q) => q.id == widget.quizId).firstOrNull;
    if (quiz == null || quiz.questions.isEmpty)
      return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: const Center(
              child: Text('Quiz not found',
                  style: TextStyle(color: Colors.white))));

    final q = quiz.questions[_current];
    final answered = _answers.length;
    final total = quiz.questions.length;
    final urgent = _remaining < 60;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(children: [
          // Header bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                  onTap: () => _showQuitDialog(),
                  child: const Icon(Icons.close, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(quiz.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('$answered/$total answered',
                        style: const TextStyle(
                            color: AppColors.darkMuted, fontSize: 12)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: urgent
                        ? AppColors.danger.withValues(alpha: 0.2)
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            urgent ? AppColors.danger : AppColors.darkBorder)),
                child: Row(children: [
                  Icon(Icons.timer,
                      size: 14,
                      color: urgent ? AppColors.danger : AppColors.accent),
                  const SizedBox(width: 4),
                  Text(_timeStr,
                      style: TextStyle(
                          color: urgent ? AppColors.danger : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
              ),
            ]),
          ),
          // Progress
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: (_current + 1) / total,
                      backgroundColor: AppColors.darkCard,
                      color: AppColors.primary,
                      minHeight: 4))),

          // Question
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Question ${_current + 1} of $total',
                  style: const TextStyle(
                      color: AppColors.darkMuted, fontSize: 13)),
              const SizedBox(height: 10),
              Text(q.questionText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.5)),
              const SizedBox(height: 24),
              ...['A', 'B', 'C', 'D'].map((opt) {
                final text = q.optionText(opt);
                if (text.isEmpty) return const SizedBox.shrink();
                final selected = _answers[q.id] == opt;
                return GestureDetector(
                  onTap: () => setState(() => _answers[q.id] = opt),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.darkBorder,
                            width: selected ? 1.5 : 1)),
                    child: Row(children: [
                      Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.darkSecondary,
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.darkBorder)),
                          child: Center(
                              child: Text(opt,
                                  style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.darkMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(text,
                              style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.darkForeground,
                                  fontSize: 14,
                                  height: 1.4))),
                    ]),
                  ),
                );
              }),
            ]),
          )),

          // Nav buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              if (_current > 0)
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppButton(
                            label: 'Previous',
                            outline: true,
                            onTap: () => setState(() => _current--)))),
              if (_current < total - 1)
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: _current > 0 ? 8 : 0),
                        child: AppButton(
                            label: 'Next',
                            onTap: () => setState(() => _current++))))
              else
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: _current > 0 ? 8 : 0),
                        child: AppButton(
                            label: 'Submit Quiz',
                            loading: _submitting,
                            onTap: _showSubmitDialog))),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showSubmitDialog() {
    final unanswered = ref
            .read(academicProvider)
            .quizzes
            .where((q) => q.id == widget.quizId)
            .first
            .questions
            .length -
        _answers.length;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.darkCard,
              title: const Text('Submit Quiz?',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              content: Text(
                  unanswered > 0
                      ? '$unanswered question(s) unanswered. Submit anyway?'
                      : 'Are you sure you want to submit?',
                  style: const TextStyle(color: AppColors.darkMuted)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _submit();
                    },
                    child: const Text('Submit',
                        style: TextStyle(color: AppColors.primary))),
              ],
            ));
  }

  void _showQuitDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.darkCard,
              title: const Text('Quit Quiz?',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              content: const Text('Progress will be lost.',
                  style: TextStyle(color: AppColors.darkMuted)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Continue')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Quit')),
              ],
            ));
  }
}
