import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/attendance_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final attendanceState = ref.watch(attendanceProvider);
    final academicState = ref.watch(academicProvider);

    if (user == null) return const SizedBox.shrink();

    final courseNames = {for (final c in academicState.courses) c.id: c.title};
    final summaries = attendanceState.summariesForStudent(user.id, courseNames);
    final overall = attendanceState.overallPercentage(user.id);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(attendanceProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(attendanceProvider.notifier).load(),
        child: attendanceState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Overall attendance card
                          _OverallCard(percentage: overall),
                          const SizedBox(height: 20),
                          if (summaries.isEmpty)
                            _EmptyState()
                          else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('By Subject', style: TextStyle(
                                color: AppColors.darkForeground, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 12),
                            ...summaries.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SubjectAttendanceCard(summary: s),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final double percentage;
  const _OverallCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75 ? AppColors.success
        : percentage >= 60 ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 8,
            percent: (percentage / 100).clamp(0, 1),
            center: Text('${percentage.toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            progressColor: color,
            backgroundColor: color.withValues(alpha: 0.15),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Attendance', style: TextStyle(
                  color: AppColors.darkForeground, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    percentage >= 75 ? 'Good Standing' : percentage >= 60 ? 'At Risk' : 'Critical',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  percentage < 75 ? '⚠️ Min 75% required for exams' : '✅ Eligible for exams',
                  style: TextStyle(color: AppColors.darkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAttendanceCard extends StatelessWidget {
  final AttendanceSummary summary;
  const _SubjectAttendanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final color = summary.percentage >= 75 ? AppColors.success
        : summary.percentage >= 60 ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(summary.courseName, style: const TextStyle(
                  color: AppColors.darkForeground, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${summary.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.percentage / 100).clamp(0, 1),
              backgroundColor: AppColors.darkBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusChip('P: ${summary.presentCount}', AppColors.success),
              const SizedBox(width: 6),
              _StatusChip('A: ${summary.absentCount}', AppColors.danger),
              const SizedBox(width: 6),
              _StatusChip('L: ${summary.lateCount}', AppColors.warning),
              const SizedBox(width: 6),
              _StatusChip('Total: ${summary.totalClasses}', AppColors.darkMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.event_note_outlined, size: 56, color: AppColors.darkMuted),
            const SizedBox(height: 12),
            const Text('No attendance records yet', style: TextStyle(color: AppColors.darkMuted)),
          ],
        ),
      ),
    );
  }
}
