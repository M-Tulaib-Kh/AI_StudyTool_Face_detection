import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/session_provider.dart';

/// Focus Insights: today's progress ring toward a daily goal, a 14-day heat strip
/// and a quick quality score. Uses only the student's own study sessions.
class FocusInsightsCard extends ConsumerStatefulWidget {
  const FocusInsightsCard({super.key});

  @override
  ConsumerState<FocusInsightsCard> createState() => _FocusInsightsCardState();
}

class _FocusInsightsCardState extends ConsumerState<FocusInsightsCard> {
  static const _prefKey = 'daily_goal_minutes';
  int _goalMinutes = 120;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getInt(_prefKey);
      if (v != null && mounted) setState(() => _goalMinutes = v.clamp(15, 480));
    } catch (_) {}
  }

  Future<void> _saveGoal(int m) async {
    setState(() => _goalMinutes = m);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_prefKey, m);
    } catch (_) {}
  }

  Future<void> _editGoal() async {
    var temp = _goalMinutes.toDouble();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Daily focus goal',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_fmt(temp.round()),
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 30, fontWeight: FontWeight.w900)),
            Slider(
              value: temp,
              min: 15,
              max: 480,
              divisions: 31,
              onChanged: (v) => setSheet(() => temp = v),
            ),
            const SizedBox(height: 8),
            AppButtonLike(
              label: 'Save goal',
              onTap: () {
                _saveGoal(temp.round());
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
  }

  static String _fmt(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionProvider).sessions;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // minutes per day for the last 14 days (oldest first)
    final days = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));
    final minutes = <DateTime, int>{for (final d in days) d: 0};
    var valid7 = 0, total7 = 0;
    for (final s in sessions) {
      final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      if (s.validSession && minutes.containsKey(d)) {
        minutes[d] = minutes[d]! + s.elapsedSeconds ~/ 60;
      }
      if (now.difference(s.startedAt).inDays < 7 && s.status != SessionStatus.active) {
        total7++;
        if (s.validSession && s.violations <= 2) valid7++;
      }
    }

    final todayMin = minutes[today] ?? 0;
    final progress = (todayMin / _goalMinutes).clamp(0.0, 1.0);
    final maxDay = minutes.values.fold<int>(0, math.max);
    final quality = total7 == 0 ? null : (valid7 * 100 / total7).round();
    final streak = _currentStreak(days.reversed.toList(), minutes);

    return ClayCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Focus Insights',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: _editGoal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.darkSecondary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.claySmall,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flag_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('Goal ${_fmt(_goalMinutes)}',
                    style: const TextStyle(
                        color: AppColors.darkForeground, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          SizedBox(
            width: 108,
            height: 108,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(
                painter: _RingPainter(v),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_fmt(todayMin),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('${(v * 100).round()}% today',
                        style: const TextStyle(color: AppColors.darkMuted, fontSize: 10.5)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Stat(Icons.local_fire_department_rounded, AppColors.warning,
                  '$streak day${streak == 1 ? '' : 's'}', 'Focus streak'),
              const SizedBox(height: 10),
              _Stat(Icons.verified_rounded, AppColors.success,
                  quality == null ? '--' : '$quality%', 'Clean sessions (7d)'),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Last 14 days',
            style: TextStyle(color: AppColors.darkMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _Cell(minutes: minutes[d]!, max: maxDay, isToday: d == today),
                ),
              ),
          ],
        ),
      ]),
    );
  }

  /// Consecutive days (ending today, or yesterday if today has none yet) with focus time.
  int _currentStreak(List<DateTime> newestFirst, Map<DateTime, int> minutes) {
    var streak = 0;
    for (var i = 0; i < newestFirst.length; i++) {
      final has = (minutes[newestFirst[i]] ?? 0) > 0;
      if (has) {
        streak++;
      } else if (i == 0) {
        continue; // today may not have started yet
      } else {
        break;
      }
    }
    return streak;
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Stat(this.icon, this.color, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ClayIconBubble(icon: icon, color: color, size: 36),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.darkMuted, fontSize: 10.5)),
        ]),
      ),
    ]);
  }
}

class _Cell extends StatelessWidget {
  final int minutes;
  final int max;
  final bool isToday;
  const _Cell({required this.minutes, required this.max, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final t = max == 0 ? 0.0 : (minutes / max).clamp(0.0, 1.0);
    final color = minutes == 0
        ? AppColors.darkSecondary
        : Color.lerp(AppColors.primary.withValues(alpha: 0.45), AppColors.accent, t)!;
    return Tooltip(
      message: '$minutes min',
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
          border: isToday ? Border.all(color: Colors.white70, width: 1.4) : null,
          boxShadow: minutes == 0 ? null : AppShadows.claySmall,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 9;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = AppColors.darkSecondary;
    canvas.drawCircle(c, r, track);
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [AppColors.primary, AppColors.gradientEnd, AppColors.accent],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// Small local button used in the goal sheet (keeps this widget self-contained).
class AppButtonLike extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AppButtonLike({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(colors: AppColors.gradientColors),
          boxShadow: AppShadows.glow(AppColors.primary),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
