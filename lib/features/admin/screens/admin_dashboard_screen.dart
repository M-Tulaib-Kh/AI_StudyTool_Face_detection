import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/shimmer_loader.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<Map<String, dynamic>> _loginEvents = [];
  int _totalUsers = 0;
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingEvents = true);
    try {
      final eventsData = await SupabaseConfig.client
          .from('login_events')
          .select()
          .order('logged_in_at', ascending: false)
          .limit(20);
      final usersData = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .count(CountOption.exact);
      if (mounted)
        setState(() {
          _loginEvents = (eventsData as List).cast<Map<String, dynamic>>();
          _totalUsers = usersData.count;
          _loadingEvents = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);
    final submissions = state.submissions.length;
    final pendingGrades = state.submissions
        .where((s) => s.status == SubmissionStatus.submitted)
        .length;

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStats();
          ref.read(academicProvider.notifier).loadAll();
        },
        color: AppColors.primary,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            elevation: 0,
            title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard',
                      style:
                          TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                  Text('StudyLock',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ]),
            actions: [
              IconButton(
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  tooltip: 'Analytics',
                  onPressed: () => context.push('/analytics')),
              IconButton(
                  icon:
                      const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => context.push('/settings')),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              // Stats grid
              GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard('Total Users', '$_totalUsers', Icons.people,
                        AppColors.primary),
                    _StatCard('Courses', '${state.courses.length}',
                        Icons.library_books, AppColors.accent),
                    _StatCard('Submissions', '$submissions',
                        Icons.assignment_turned_in, AppColors.success),
                    _StatCard(
                        'Pending Grades',
                        '$pendingGrades',
                        Icons.grading,
                        pendingGrades > 0
                            ? AppColors.warning
                            : AppColors.success),
                  ]),
              const SizedBox(height: 24),
              Row(children: [
                const Text('Recent Logins',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                    onPressed: _loadStats,
                    child: const Text('Refresh',
                        style: TextStyle(color: AppColors.primary))),
              ]),
              const SizedBox(height: 12),
              if (_loadingEvents)
                const ShimmerList(count: 4)
              else if (_loginEvents.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No login events',
                        style: TextStyle(color: AppColors.darkMuted)))
              else
                ..._loginEvents.map((e) {
                  final time =
                      DateTime.tryParse(e['logged_in_at'] as String? ?? '');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.darkBorder)),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                              (e['name'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(e['name'] as String? ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(e['email'] as String? ?? '',
                                style: const TextStyle(
                                    color: AppColors.darkMuted, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ])),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _RoleBadge(e['role'] as String? ?? 'student'),
                            if (time != null)
                              Text(
                                  DateFormat('MMM d, HH:mm')
                                      .format(time.toLocal()),
                                  style: const TextStyle(
                                      color: AppColors.darkMuted,
                                      fontSize: 10)),
                          ]),
                    ]),
                  );
                }),
              const SizedBox(height: 40),
            ])),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 26, fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
      ]));
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);
  @override
  Widget build(BuildContext context) {
    final color = role == 'admin'
        ? AppColors.danger
        : role == 'lecturer'
            ? AppColors.accent
            : AppColors.success;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Text(role,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }
}
