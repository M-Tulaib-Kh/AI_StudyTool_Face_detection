// ============================================================
// StudyLock — Parent Portal Screen
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';

class ParentChildData {
  final String name;
  final String email;
  final String department;
  final int points;
  final int streak;
  final double attendancePct;
  final double avgQuizScore;
  final int totalSessions;
  final int studyMinutes;
  const ParentChildData({
    required this.name,
    required this.email,
    required this.department,
    required this.points,
    required this.streak,
    required this.attendancePct,
    required this.avgQuizScore,
    required this.totalSessions,
    required this.studyMinutes,
  });
}

final parentChildProvider = FutureProvider.family
    .autoDispose<ParentChildData?, String>((ref, childEmail) async {
  try {
    // Server-side aggregate (RPC): the app never reads another student's raw rows.
    final res = await SupabaseConfig.client
        .rpc('parent_child_summary', params: {'child_email': childEmail.trim()});
    if (res == null) return null;
    final m = Map<String, dynamic>.from(res as Map);
    return ParentChildData(
      name: m['name'] as String? ?? '',
      email: childEmail,
      department: m['department'] as String? ?? '',
      points: (m['points'] as num?)?.toInt() ?? 0,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      attendancePct: (m['attendance_pct'] as num?)?.toDouble() ?? 0,
      avgQuizScore: (m['avg_quiz_score'] as num?)?.toDouble() ?? 0,
      totalSessions: (m['total_sessions'] as num?)?.toInt() ?? 0,
      studyMinutes: (m['study_minutes'] as num?)?.toInt() ?? 0,
    );
  } catch (_) {
    return null;
  }
});

class ParentPortalScreen extends ConsumerStatefulWidget {
  const ParentPortalScreen({super.key});
  @override
  ConsumerState<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends ConsumerState<ParentPortalScreen> {
  final _emailCtrl = TextEditingController();
  String? _searchEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Parent Portal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Search child by email
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder)),
            child: Column(children: [
              const Row(children: [
                Icon(Icons.people_alt, color: AppColors.primary),
                SizedBox(width: 8),
                Text('View Your Child\'s Progress',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter child\'s registered email',
                  hintStyle: const TextStyle(color: AppColors.darkMuted),
                  filled: true,
                  fillColor: AppColors.darkSecondary,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.darkBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.darkBorder)),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.darkMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: () => setState(() =>
                        _searchEmail = _emailCtrl.text.trim().toLowerCase()),
                  ),
                ),
                onSubmitted: (v) =>
                    setState(() => _searchEmail = v.trim().toLowerCase()),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          if (_searchEmail != null && _searchEmail!.isNotEmpty)
            Expanded(child: _ChildReport(email: _searchEmail!)),
        ]),
      ),
    );
  }
}

class _ChildReport extends ConsumerWidget {
  final String email;
  const _ChildReport({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(parentChildProvider(email));
    return dataAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.danger))),
      data: (data) {
        if (data == null)
          return const Center(
              child: Text('Student not found with this email.',
                  style: TextStyle(color: AppColors.darkMuted)));
        return SingleChildScrollView(
            child: Column(children: [
          // Student header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.accent.withValues(alpha: 0.1)
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                      data.name.isNotEmpty ? data.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900))),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(data.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text(data.department,
                        style: const TextStyle(color: AppColors.darkMuted)),
                    Text(data.email,
                        style: const TextStyle(
                            color: AppColors.darkMuted, fontSize: 12)),
                  ])),
            ]),
          ),
          const SizedBox(height: 16),
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                  'Attendance',
                  '${data.attendancePct.toStringAsFixed(1)}%',
                  Icons.event_note_outlined,
                  data.attendancePct >= 75
                      ? AppColors.success
                      : AppColors.danger),
              _StatCard(
                  'Avg Score',
                  '${data.avgQuizScore.toStringAsFixed(1)}%',
                  Icons.quiz_outlined,
                  data.avgQuizScore >= 60
                      ? AppColors.success
                      : AppColors.warning),
              _StatCard('Study Points', '${data.points}', Icons.star_outlined,
                  AppColors.warning),
              _StatCard('Study Streak', '${data.streak} days',
                  Icons.local_fire_department_outlined, AppColors.accent),
              _StatCard('Sessions', '${data.totalSessions}',
                  Icons.timer_outlined, AppColors.primary),
              _StatCard('Study Time', '${data.studyMinutes} min',
                  Icons.access_time, AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          // Attendance warning
          if (data.attendancePct < 75)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Attendance Warning',
                          style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${data.name}\'s attendance is ${data.attendancePct.toStringAsFixed(1)}%. Minimum 75% required for exams.',
                          style: const TextStyle(
                              color: AppColors.darkForeground, fontSize: 12)),
                    ])),
              ]),
            ),
        ]));
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.darkMuted, fontSize: 11)),
              ]),
            ]),
      );
}
