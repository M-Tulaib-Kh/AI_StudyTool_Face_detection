import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Analytics Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(analyticsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(analyticsProvider.notifier).load(),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Summary stats grid
                        _SectionTitle('Platform Overview'),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _StatCard('Students', state.data.totalStudents.toString(), Icons.people, AppColors.primary),
                            _StatCard('Lecturers', state.data.totalLecturers.toString(), Icons.person_4, AppColors.accent),
                            _StatCard('Courses', state.data.totalCourses.toString(), Icons.book, AppColors.success),
                            _StatCard('Lectures', state.data.totalLectures.toString(), Icons.video_library, AppColors.warning),
                            _StatCard('Assignments', state.data.totalAssignments.toString(), Icons.assignment, AppColors.danger),
                            _StatCard('Quiz Attempts', state.data.totalQuizAttempts.toString(), Icons.quiz, AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Avg quiz score
                        _SectionTitle('Average Quiz Score'),
                        const SizedBox(height: 12),
                        _AvgScoreCard(score: state.data.avgQuizScore),
                        const SizedBox(height: 24),
                        // Department breakdown
                        if (state.data.departmentStats.isNotEmpty) ...[
                          _SectionTitle('Students by Department'),
                          const SizedBox(height: 12),
                          _DepartmentChart(stats: state.data.departmentStats),
                          const SizedBox(height: 24),
                        ],
                        // Content stats
                        _SectionTitle('Content Statistics'),
                        const SizedBox(height: 12),
                        _ContentStatsCard(state: state),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(
      color: AppColors.darkForeground, fontSize: 16, fontWeight: FontWeight.w700));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvgScoreCard extends StatelessWidget {
  final double score;
  const _AvgScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70 ? AppColors.success : score >= 50 ? AppColors.warning : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${score.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900)),
                const Text('Average score across all quizzes',
                  style: TextStyle(color: AppColors.darkMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.trending_up, color: color, size: 28),
          ),
        ],
      ),
    );
  }
}

class _DepartmentChart extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const _DepartmentChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, AppColors.accent, AppColors.success, AppColors.warning, AppColors.danger];
    final total = stats.fold<int>(0, (s, e) => s + (e['count'] as int));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(PieChartData(
              sections: stats.asMap().entries.map((e) {
                final pct = total > 0 ? (e.value['count'] as int) / total : 0.0;
                return PieChartSectionData(
                  value: pct * 100,
                  color: colors[e.key % colors.length],
                  title: '${(pct * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  radius: 60,
                );
              }).toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: stats.asMap().entries.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: colors[e.key % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${e.value['department']} (${e.value['count']})',
                  style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ContentStatsCard extends StatelessWidget {
  final AnalyticsState state;
  const _ContentStatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          _Row('Total Quizzes', state.data.totalQuizzes.toString()),
          _Row('Total Submissions', state.data.totalSubmissions.toString()),
          _Row('Avg Quiz Score', '${state.data.avgQuizScore.toStringAsFixed(1)}%'),
          _Row('Quiz Attempts', state.data.totalQuizAttempts.toString()),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.darkForeground, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
