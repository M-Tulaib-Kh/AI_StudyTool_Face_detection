import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CircularTimerWidget extends StatelessWidget {
  final int elapsed;
  final int total;
  final double size;
  const CircularTimerWidget({super.key, required this.elapsed, required this.total, this.size = 260});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    final remaining = (total - elapsed).clamp(0, total);
    final h = remaining ~/ 3600;
    final m = (remaining % 3600) ~/ 60;
    final s = remaining % 60;
    final timeStr = h > 0 ? '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}' : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';

    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _TimerPainter(progress: progress),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(timeStr,
              style: TextStyle(color: Colors.white, fontSize: size * 0.13,
                fontWeight: FontWeight.w800, letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 4),
            Text('remaining', style: TextStyle(color: AppColors.darkMuted, fontSize: size * 0.055)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${(progress * 100).toInt()}% complete',
                style: TextStyle(color: AppColors.success, fontSize: size * 0.048, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  const _TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 16;
    const sw = 10.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background track
    canvas.drawArc(rect, -pi / 2, 2 * pi, false,
      Paint()..color = AppColors.darkSecondary..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);

    if (progress > 0) {
      // Gradient arc
      final grad = SweepGradient(
        startAngle: -pi / 2, endAngle: -pi / 2 + 2 * pi * progress,
        colors: const [AppColors.primary, AppColors.accent],
      );
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false,
        Paint()..shader = grad.createShader(rect)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) => old.progress != progress;
}
