import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Claymorphism design kit for StudyLock (dark "midnight clay" look).
/// Soft, puffy surfaces: big radii, a dark drop shadow bottom-right and a faint
/// highlight top-left, gradient fills and gentle glow instead of hard borders.
class AppShadows {
  /// Standard puffy card shadow.
  static const clay = <BoxShadow>[
    BoxShadow(color: Color(0x66050714), blurRadius: 26, offset: Offset(10, 12)),
    BoxShadow(color: Color(0x14FFFFFF), blurRadius: 18, offset: Offset(-6, -6)),
  ];

  /// Smaller version for chips, small buttons and icon bubbles.
  static const claySmall = <BoxShadow>[
    BoxShadow(color: Color(0x59050714), blurRadius: 14, offset: Offset(5, 6)),
    BoxShadow(color: Color(0x12FFFFFF), blurRadius: 10, offset: Offset(-3, -3)),
  ];

  /// Coloured glow for primary actions.
  static List<BoxShadow> glow(Color c) => [
        BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
        const BoxShadow(color: Color(0x55050714), blurRadius: 16, offset: Offset(6, 8)),
      ];
}

/// Solid base colour plus soft blobs anchored to the TOP of the screen, so the
/// background looks identical on every page (no seams with the floating nav).
class ClayBackdrop extends StatelessWidget {
  const ClayBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: AppColors.darkBackground),
        Positioned(top: -140, left: -100, child: _Blob(size: 340, color: AppColors.primary.withValues(alpha: 0.30))),
        Positioned(top: 120, right: -150, child: _Blob(size: 340, color: AppColors.gradientEnd.withValues(alpha: 0.22))),
        Positioned(top: 460, left: -170, child: _Blob(size: 320, color: AppColors.accent.withValues(alpha: 0.12))),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Drop-in replacement for [Scaffold]: same common parameters, claymorphism backdrop.
class ClayScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor; // kept for API compatibility, ignored
  const ClayScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const ClayBackdrop(),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    ]);
  }
}

/// Puffy card.
class ClayCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final List<Color>? gradient;
  final VoidCallback? onTap;
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 28,
    this.color,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.darkCard;
    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ?? [Color.lerp(base, Colors.white, 0.07)!, base],
        ),
        boxShadow: AppShadows.clay,
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: box);
  }
}

/// Round puffy icon holder.
class ClayIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const ClayIconBubble({super.key, required this.icon, this.color = AppColors.primary, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        boxShadow: AppShadows.glow(color),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

class ClayNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const ClayNavItem(this.icon, this.activeIcon, this.label);
}

/// Floating pill navigation bar.
class ClayFloatingNav extends StatelessWidget {
  final int currentIndex;
  final List<ClayNavItem> items;
  final ValueChanged<int> onTap;
  const ClayFloatingNav({super.key, required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(AppColors.darkCard, Colors.white, 0.08)!, AppColors.darkCard],
            ),
            boxShadow: AppShadows.clay,
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  flex: i == currentIndex ? 2 : 1,
                  child: _NavButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final ClayNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: selected ? const LinearGradient(colors: AppColors.gradientColors) : null,
            boxShadow: selected ? AppShadows.glow(AppColors.primary) : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? item.activeIcon : item.icon,
                  size: 22, color: selected ? Colors.white : AppColors.darkMuted),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(item.label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
