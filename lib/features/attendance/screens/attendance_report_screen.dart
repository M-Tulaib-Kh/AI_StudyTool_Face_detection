import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/attendance_model.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  String? _selectedCourseId;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentRoleProvider);
    final attendance = ref.watch(attendanceProvider);
    final academic = ref.watch(academicProvider);

    if (user == null) return const SizedBox.shrink();

    final isLecturer = role == UserRole.lecturer || role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          isLecturer ? 'Mark Attendance' : 'Attendance Report',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLecturer
          ? _LecturerView(
              courses: academic.courses
                  .where(
                      (c) => role == UserRole.admin || c.lecturerId == user.id)
                  .toList(),
              user: user,
              attendance: attendance,
              selectedDate: _selectedDate,
              selectedCourseId: _selectedCourseId,
              onCourseSelected: (id) => setState(() => _selectedCourseId = id),
              onDateSelected: (d) => setState(() => _selectedDate = d),
            )
          : _StudentReport(userId: user.id, attendance: attendance),
    );
  }
}

class _StudentReport extends StatelessWidget {
  final String userId;
  final AttendanceState attendance;

  const _StudentReport({required this.userId, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final records = attendance.forStudent(userId);
    if (records.isEmpty) {
      return const Center(
        child: Text('No attendance records',
            style: TextStyle(color: AppColors.darkMuted)),
      );
    }

    // Group by date
    final byDate = <String, List<AttendanceRecord>>{};
    for (final r in records) {
      final key =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => []).add(r);
    }

    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dates.length,
      itemBuilder: (_, i) {
        final dateKey = dates[i];
        final dayRecords = byDate[dateKey]!;
        return _DateGroup(dateKey: dateKey, records: dayRecords);
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String dateKey;
  final List<AttendanceRecord> records;
  const _DateGroup({required this.dateKey, required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(dateKey,
              style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        ...records.map((r) {
          final statusColor = switch (r.status) {
            AttendanceStatus.present => AppColors.success,
            AttendanceStatus.late => AppColors.warning,
            AttendanceStatus.excused => AppColors.primary,
            AttendanceStatus.absent => AppColors.danger,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(r.courseId,
                        style: const TextStyle(
                            color: AppColors.darkForeground, fontSize: 13))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(r.status.label,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _LecturerView extends ConsumerStatefulWidget {
  final List<dynamic> courses;
  final dynamic user;
  final AttendanceState attendance;
  final DateTime selectedDate;
  final String? selectedCourseId;
  final void Function(String?) onCourseSelected;
  final void Function(DateTime) onDateSelected;

  const _LecturerView({
    required this.courses,
    required this.user,
    required this.attendance,
    required this.selectedDate,
    required this.selectedCourseId,
    required this.onCourseSelected,
    required this.onDateSelected,
  });

  @override
  ConsumerState<_LecturerView> createState() => _LecturerViewState();
}

class _LecturerViewState extends ConsumerState<_LecturerView> {
  final Map<String, AttendanceStatus> _statuses = {};
  bool _saving = false;

  Future<void> _save() async {
    if (widget.selectedCourseId == null || _statuses.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(attendanceProvider.notifier).markBulkAttendance(
        courseId: widget.selectedCourseId!,
        lecturerId: widget.user.id as String,
        date: widget.selectedDate,
        studentStatuses: _statuses,
        studentNames: {
          for (final st in ref
                  .read(courseRosterProvider(widget.selectedCourseId!))
                  .valueOrNull ??
              const <RosterStudent>[])
            st.id: st.name
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Attendance saved'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.darkSurface,
          child: Column(
            children: [
              // Course selector
              DropdownButtonFormField<String>(
                initialValue: widget.selectedCourseId,
                decoration: InputDecoration(
                  labelText: 'Select Course',
                  labelStyle: const TextStyle(color: AppColors.darkMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.darkBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.darkBorder)),
                ),
                dropdownColor: AppColors.darkCard,
                style: const TextStyle(color: AppColors.darkForeground),
                items: widget.courses
                    .map((c) => DropdownMenuItem<String>(
                          value: c.id as String,
                          child: Text(c.title as String,
                              style: const TextStyle(
                                  color: AppColors.darkForeground)),
                        ))
                    .toList(),
                onChanged: (v) {
                  widget.onCourseSelected(v);
                  setState(() => _statuses.clear());
                },
              ),
              const SizedBox(height: 12),
              // Date picker row
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) widget.onDateSelected(picked);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                          '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}',
                          style:
                              const TextStyle(color: AppColors.darkForeground)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.darkMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.selectedCourseId != null) ...[
          Expanded(
            child: _StudentAttendanceList(
              courseId: widget.selectedCourseId!,
              statuses: _statuses,
              onStatusChanged: (studentId, status) {
                setState(() => _statuses[studentId] = status);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _statuses.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Save Attendance (${_statuses.length} students)',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Text('Select a course to mark attendance',
                  style: TextStyle(color: AppColors.darkMuted)),
            ),
          ),
      ],
    );
  }
}

class _StudentAttendanceList extends ConsumerWidget {
  final String courseId;
  final Map<String, AttendanceStatus> statuses;
  final void Function(String, AttendanceStatus) onStatusChanged;

  const _StudentAttendanceList({
    required this.courseId,
    required this.statuses,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(courseRosterProvider(courseId));
    return roster.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Could not load students for this course.',
              style: TextStyle(color: AppColors.darkMuted),
              textAlign: TextAlign.center),
        ),
      ),
      data: (students) {
        if (students.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: AppColors.darkMuted),
                  SizedBox(height: 12),
                  Text('No enrolled students found',
                      style: TextStyle(color: AppColors.darkMuted)),
                  SizedBox(height: 8),
                  Text('Students must enrol in this course first.',
                      style: TextStyle(color: AppColors.darkMuted, fontSize: 12),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final st = students[i];
            final current = statuses[st.id];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(st.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AttendanceStatus.values.map((a) {
                      return ChoiceChip(
                        label: Text(a.label),
                        selected: current == a,
                        onSelected: (_) => onStatusChanged(st.id, a),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
