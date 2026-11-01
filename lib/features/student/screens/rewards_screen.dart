import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../shared/widgets/shimmer_loader.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);

    if (game == null) return const ClayScaffold(backgroundColor: Color(0xFF060E1A),
      body: Padding(padding: EdgeInsets.all(16), child: ShimmerList(count: 5)));

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Rewards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Image.asset('assets/images/hero_rewards.png',
                height: 140,
                errorBuilder: (_, __, ___) => const SizedBox(height: 140)),
          ),
          const SizedBox(height: 8),
          // Level card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.gradientEnd]),
              boxShadow: AppShadows.glow(AppColors.primary),
              borderRadius: BorderRadius.circular(28)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.military_tech, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text('Level ${game.level}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${game.points} XP', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: game.levelProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2), color: Colors.white, minHeight: 8)),
              const SizedBox(height: 8),
              Text('${(game.levelProgress * 100).toInt()}% to Level ${game.level + 1}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])).animate().fadeIn(),

          const SizedBox(height: 20),
          // Streak + stats
          Row(children: [
            _StatBox(icon: Icons.local_fire_department, label: 'Current Streak', value: '${game.streak}d', color: AppColors.warning),
            const SizedBox(width: 12),
            _StatBox(icon: Icons.emoji_events, label: 'Best Streak', value: '${game.longestStreak}d', color: AppColors.accent),
            const SizedBox(width: 12),
            _StatBox(icon: Icons.timer, label: 'Total Study', value: _fmtH(session.totalStudySeconds), color: AppColors.success),
          ]).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),
          const Text('Challenges', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...game.challenges.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(boxShadow: AppShadows.clay, 
              color: c.completed ? AppColors.success.withValues(alpha: 0.1) : AppColors.darkCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.completed ? AppColors.success.withValues(alpha: 0.3) : AppColors.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title, style: TextStyle(color: c.completed ? AppColors.success : Colors.white, fontWeight: FontWeight.w600)),
                  Text(c.description, style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('+${c.reward} XP', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: c.progress,
                  backgroundColor: AppColors.darkSecondary,
                  color: c.completed ? AppColors.success : AppColors.primary, minHeight: 6)),
              const SizedBox(height: 4),
              Text('${c.current} / ${c.target} ${c.unit}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
            ])).animate().fadeIn(delay: Duration(milliseconds: 150 * game.challenges.indexOf(c)))),

          const SizedBox(height: 24),
          const Text('Badges', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
            children: game.badges.map((b) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                color: b.unlocked ? AppColors.primary.withValues(alpha: 0.1) : AppColors.darkCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: b.unlocked ? AppColors.primary.withValues(alpha: 0.4) : AppColors.darkBorder)),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: (b.unlocked ? AppColors.primary : AppColors.darkMuted).withValues(alpha: 0.15)),
                  child: Icon(_badgeIcon(b.icon), color: b.unlocked ? AppColors.primary : AppColors.darkMuted, size: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b.name, style: TextStyle(color: b.unlocked ? Colors.white : AppColors.darkMuted,
                    fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(b.description, style: const TextStyle(color: AppColors.darkMuted, fontSize: 10),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  String _fmtH(int s) { final h = s ~/ 3600; return '${h}h'; }

  IconData _badgeIcon(String icon) => switch (icon) {
    'award' => Icons.emoji_events,
    'flame' => Icons.local_fire_department,
    'book'  => Icons.menu_book,
    'library' => Icons.library_books,
    'eye'   => Icons.center_focus_strong,
    'time'  => Icons.access_time,
    'sunny' => Icons.wb_sunny,
    _       => Icons.star,
  };
}

class _StatBox extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _StatBox({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(boxShadow: AppShadows.clay, color: AppColors.darkCard, borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.darkBorder)),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 10), textAlign: TextAlign.center),
    ])));
}
