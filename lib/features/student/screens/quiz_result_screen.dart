import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/academic_provider.dart';
import '../../../shared/widgets/app_button.dart';

class QuizResultScreen extends ConsumerWidget {
  final String attemptId;
  const QuizResultScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(academicProvider);
    final attempt = state.attempts.where((a) => a.id == attemptId).firstOrNull;
    if (attempt == null) return ClayScaffold(backgroundColor: Colors.transparent,
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Result not found', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => context.go('/student/academic'), child: const Text('Back')),
      ])));

    final quiz = state.quizzes.where((q) => q.id == attempt.quizId).firstOrNull;
    final pct = attempt.totalMarks > 0 ? attempt.score / attempt.totalMarks : 0.0;
    final passed = pct >= 0.5;
    final grade = pct >= 0.9 ? 'A+' : pct >= 0.8 ? 'A' : pct >= 0.7 ? 'B' : pct >= 0.6 ? 'C' : pct >= 0.5 ? 'D' : 'F';

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: (passed ? AppColors.success : AppColors.danger).withValues(alpha: 0.15)),
              child: Center(child: Text(grade,
                style: TextStyle(color: passed ? AppColors.success : AppColors.danger,
                  fontSize: 40, fontWeight: FontWeight.w900))),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(passed ? 'Well Done! 🎉' : 'Keep Practicing',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))
                .animate().fadeIn(delay: 200.ms),
            if (quiz != null) ...[
              const SizedBox(height: 4),
              Text(quiz.title, style: const TextStyle(color: AppColors.darkMuted, fontSize: 14)).animate().fadeIn(delay: 250.ms),
            ],
            const SizedBox(height: 28),
            Row(children: [
              _ResultStat(label: 'Score', value: '${attempt.score}', sub: '/ ${attempt.totalMarks}', color: passed ? AppColors.success : AppColors.danger),
              const SizedBox(width: 12),
              _ResultStat(label: 'Percentage', value: '${(pct * 100).toInt()}%', color: AppColors.primary),
              const SizedBox(width: 12),
              _ResultStat(label: 'Grade', value: grade, color: passed ? AppColors.success : AppColors.warning),
            ]).animate().fadeIn(delay: 300.ms),

            if (attempt.aiFeedback != null && attempt.aiFeedback!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                    SizedBox(width: 8), Text('AI Feedback', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 10),
                  Text(attempt.aiFeedback!, style: const TextStyle(color: AppColors.darkForeground, fontSize: 14, height: 1.6)),
                ]),
              ).animate().fadeIn(delay: 400.ms),
            ],

            // Question breakdown
            if (quiz != null) ...[
              const SizedBox(height: 24),
              const Align(alignment: Alignment.centerLeft,
                child: Text('Answer Review', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),
              ...quiz.questions.asMap().entries.map((e) {
                final q = e.value;
                final answered = attempt.answers[q.id];
                final correct = answered == q.correctAnswer;
                final color = answered == null ? AppColors.darkMuted : correct ? AppColors.success : AppColors.danger;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(answered == null ? Icons.remove_circle_outline : correct ? Icons.check_circle : Icons.cancel, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Q${e.key + 1}: ${q.questionText}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Your answer: ${answered != null ? '(${answered}) ${q.optionText(answered)}' : 'Not answered'}',
                      style: TextStyle(color: correct ? AppColors.success : AppColors.danger, fontSize: 12)),
                    if (!correct) Text('Correct: (${q.correctAnswer}) ${q.optionText(q.correctAnswer)}',
                      style: const TextStyle(color: AppColors.success, fontSize: 12)),
                  ]),
                );
              }),
            ],

            const SizedBox(height: 24),
            AppButton(label: 'Back to Academic', onTap: () => context.go('/student/academic')),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label, value; final String? sub; final Color color;
  const _ResultStat({required this.label, required this.value, this.sub, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
        if (sub != null) Text(sub!, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 13)),
      ]),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
    ]),
  ));
}
