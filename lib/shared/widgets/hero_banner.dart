import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Big claymorphism banner with a 3D-style illustration on the right.
class HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset;
  final String? actionLabel;
  final VoidCallback? onTap;
  final List<Color> gradient;

  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.actionLabel,
    this.onTap,
    this.gradient = const [Color(0xFF2B2F6B), Color(0xFF1E2244)],
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      gradient: gradient,
      padding: EdgeInsets.zero,
      radius: 32,
      onTap: onTap,
      child: SizedBox(
        height: 150,
        child: Stack(children: [
          Positioned(
            right: -6,
            top: 0,
            bottom: 0,
            child: Image.asset(
              asset,
              width: 190,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 150, 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.15)),
                const SizedBox(height: 6),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkMuted, fontSize: 12.5, height: 1.35)),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(colors: AppColors.gradientColors),
                      boxShadow: AppShadows.claySmall,
                    ),
                    child: Text(actionLabel!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
