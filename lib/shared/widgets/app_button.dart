import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    final handler = onTap ?? onPressed;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: outline ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : handler,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: outline
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bg, width: 1.5),
                  )
                : null,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: outline ? bg : Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[
                        Icon(icon, color: outline ? bg : Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: TextStyle(
                              color: outline ? bg : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}
