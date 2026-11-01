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

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => t.$1 == loc);
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      body: child,
      bottomNavigationBar: ClayFloatingNav(
        currentIndex: _index(context),
        items: [for (final t in _tabs) ClayNavItem(t.$2, t.$3, t.$4)],
        onTap: (i) => context.go(_tabs[i].$1),
      ),
    );
  }
}
