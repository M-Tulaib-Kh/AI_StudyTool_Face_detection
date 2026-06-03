import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  static const _tabs = [
    ('/student', Icons.home_outlined, Icons.home, 'Home'),
    ('/student/academic', Icons.school_outlined, Icons.school, 'Academic'),
    ('/student/session', Icons.timer_outlined, Icons.timer, 'Session'),
    ('/student/rewards', Icons.emoji_events_outlined, Icons.emoji_events, 'Rewards'),
    ('/student/profile', Icons.person_outlined, Icons.person, 'Profile'),
  ];

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => t.$1 == loc);
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          border: Border(top: BorderSide(color: AppColors.darkBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(height: 60,
            child: Row(
              children: _tabs.asMap().entries.map((e) {
                final selected = e.key == idx;
                final tab = e.value;
                return Expanded(child: GestureDetector(
                  onTap: () => context.go(tab.$1),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(selected ? tab.$3 : tab.$2,
                      color: selected ? AppColors.primary : AppColors.darkMuted, size: 22),
                    const SizedBox(height: 3),
                    Text(tab.$4, style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.darkMuted,
                      fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                  ]),
                ));
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
