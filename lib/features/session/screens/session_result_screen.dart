import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

class SessionResultScreen extends StatelessWidget {
  final String status;
  final int durationSeconds, violations, pointsEarned;
  const SessionResultScreen({super.key, required this.status, required this.durationSeconds, required this.violations, required this.pointsEarned});

  bool get _success => status == 'completed';

  String _fmt(int s) {
    final h = s ~/ 3600; final m = (s % 3600) ~/ 60; final sec = s % 60;
    if (h > 0) return '${h}h ${m}m ${sec}s';
    return '${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _success ? AppColors.success : AppColors.danger;
    final icon = _success ? Icons.check_circle_outline : Icons.cancel_outlined;
    final title = _success ? 'Session Complete! 🎉' : 'Session Failed';
    final subtitle = _success ? 'Great work! Keep up the momentum.' : 'Too many violations. Try again with better focus.';
    final efficiency = violations == 0 ? 100 : (100 - (violations * 33)).clamp(0, 100);

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 40),
            Icon(icon, size: 80, color: color).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppColors.darkMuted, fontSize: 15), textAlign: TextAlign.center).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 36),

            // Stats
            Row(children: [
              _StatBubble(label: 'Duration', value: _fmt(durationSeconds), icon: Icons.timer, color: AppColors.primary),
              const SizedBox(width: 12),
              _StatBubble(label: 'Violations', value: '$violations/3', icon: Icons.warning_amber_outlined, color: violations > 0 ? AppColors.warning : AppColors.success),
              const SizedBox(width: 12),
              _StatBubble(label: 'Focus', value: '$efficiency%', icon: Icons.center_focus_strong, color: AppColors.accent),
            ]).animate().fadeIn(delay: 400.ms),

            if (_success && pointsEarned > 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.gradientEnd]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('XP Earned', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('+$pointsEarned XP', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.8, 0.8)),
            ],

            const Spacer(),
            AppButton(label: 'Back to Home', onTap: () => context.go('/student')),
            const SizedBox(height: 12),
            AppButton(label: 'Start Another Session', outline: true, onTap: () => context.go('/student/session')),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatBubble({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
    ]),
  ));
}
