import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Claymorphism button: puffy gradient pill with a soft glow and a press animation.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onPressed; // alias for onTap
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.onPressed,
    this.loading = false,
    this.outline = false,
    this.icon,
    this.color,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppColors.primary;
    final handler = widget.onTap ?? widget.onPressed;
    final enabled = handler != null && !widget.loading;
    final fg = widget.outline ? base : Colors.white;

    final decoration = widget.outline
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: AppColors.darkCard,
            border: Border.all(color: base.withValues(alpha: 0.7), width: 1.5),
            boxShadow: AppShadows.claySmall,
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.color == null
                  ? AppColors.gradientColors
                  : [Color.lerp(base, Colors.white, 0.22)!, base],
            ),
            boxShadow: AppShadows.glow(base),
          );

    return Opacity(
      opacity: enabled || widget.loading ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled ? handler : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: decoration,
            alignment: Alignment.center,
            child: widget.loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label,
                        style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800)),
                  ]),
          ),
        ),
      ),
    );
  }
}
