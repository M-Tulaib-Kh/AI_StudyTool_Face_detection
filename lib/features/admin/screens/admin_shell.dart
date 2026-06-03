import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});
  static const _tabs = [
    ('/admin', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    ('/admin/users', Icons.people_outlined, Icons.people, 'Users'),
    ('/admin/courses', Icons.school_outlined, Icons.school, 'Courses'),
  ];
  int _idx(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    final i = _tabs.indexWhere((t) => t.$1 == loc);
    return i == -1 ? 0 : i;
  }
  @override
  Widget build(BuildContext context) {
    final idx = _idx(context);
    return Scaffold(
      backgroundColor: AppColors.darkBackground, body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.darkCard, border: Border(top: BorderSide(color: AppColors.darkBorder, width: 0.5))),
        child: SafeArea(child: SizedBox(height: 60,
          child: Row(children: _tabs.asMap().entries.map((e) {
            final sel = e.key == idx; final t = e.value;
            return Expanded(child: GestureDetector(
              onTap: () => context.go(t.$1), behavior: HitTestBehavior.opaque,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(sel ? t.$3 : t.$2, color: sel ? AppColors.primary : AppColors.darkMuted, size: 22),
                const SizedBox(height: 3),
                Text(t.$4, style: TextStyle(color: sel ? AppColors.primary : AppColors.darkMuted,
                  fontSize: 10, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ]),
            ));
          }).toList()))),
      ),
    );
  }
}
