import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/gpa_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/gpa_model.dart';

class GPAScreen extends ConsumerWidget {
  const GPAScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gpaProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('GPA & Grades', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(academicProvider.notifier).loadAll(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.summary == null || state.summary!.semesters.isEmpty
              ? _EmptyGPA()
              : _GPAContent(summary: state.summary!),
    );
  }
}

class _GPAContent extends StatelessWidget {
  final GPASummary summary;
  const _GPAContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cgpa = summary.cgpa;
    final cgpaColor = cgpa >= 3.5 ? AppColors.success
        : cgpa >= 2.5 ? AppColors.warning
        : AppColors.danger;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // CGPA Hero Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.accent.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('CGPA', style: const TextStyle(color: AppColors.darkMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(cgpa.toStringAsFixed(2), style: TextStyle(
                      color: cgpaColor, fontSize: 56, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('/ 4.00', style: const TextStyle(color: AppColors.darkMuted, fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: cgpaColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(summary.cgpaClassification, style: TextStyle(
                        color: cgpaColor, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoChip('Credits', summary.totalCreditHours.toString()),
                        const SizedBox(width: 12),
                        _InfoChip('Semesters', summary.semesters.length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // GPA Bar Chart
              if (summary.semesters.length > 1) ...[
                const Text('GPA Trend', style: TextStyle(
                  color: AppColors.darkForeground, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(height: 180, child: _GPAChart(semesters: summary.semesters)),
                const SizedBox(height: 24),
              ],
              // Semester breakdown
              ...summary.semesters.map((sem) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _SemesterCard(semester: sem),
              )),
            ]),
          ),
        ),
      ],
    );
  }
}

class _GPAChart extends StatelessWidget {
  final List<SemesterGPA> semesters;
  const _GPAChart({required this.semesters});

  @override
  Widget build(BuildContext context) {
    return BarChart(BarChartData(
      barGroups: semesters.asMap().entries.map((e) => BarChartGroupData(
        x: e.key,
        barRods: [BarChartRodData(
          toY: e.value.gpa,
          color: AppColors.primary,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 4, color: AppColors.darkCard),
        )],
      )).toList(),
      maxY: 4,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= semesters.length) return const SizedBox.shrink();
            return Text('S${semesters[i].semester}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 10));
          },
        )),
      ),
    ));
  }
}

class _SemesterCard extends StatelessWidget {
  final SemesterGPA semester;
  const _SemesterCard({required this.semester});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text('Semester ${semester.semester}', style: const TextStyle(
                  color: AppColors.darkForeground, fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('GPA: ${semester.gpa.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          ...semester.courses.map((c) => _GradeRow(course: c)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.darkSecondary.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text('${semester.totalCreditHours} Credit Hours', style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
                const Spacer(),
                Text('QP: ${semester.totalQualityPoints.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final CourseGrade course;
  const _GradeRow({required this.course});

  @override
  Widget build(BuildContext context) {
    final gradeColor = course.gradePoints >= 3.0 ? AppColors.success
        : course.gradePoints >= 2.0 ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.darkBorder, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.courseName, style: const TextStyle(color: AppColors.darkForeground, fontSize: 13)),
                Text('${course.creditHours} cr • ${course.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(course.grade.label, style: TextStyle(
              color: gradeColor, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _EmptyGPA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: AppColors.darkMuted),
          SizedBox(height: 16),
          Text('No grades yet', style: TextStyle(color: AppColors.darkMuted, fontSize: 16)),
          SizedBox(height: 8),
          Text('Complete quizzes and assignments\nto see your GPA', style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
