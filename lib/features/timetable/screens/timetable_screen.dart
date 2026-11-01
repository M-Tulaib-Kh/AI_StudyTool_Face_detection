// ============================================================
// StudyLock — Timetable / Academic Calendar Screen
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class TimetableEntry {
  final String id;
  final String userId;
  final String subject;
  final String instructor;
  final int dayOfWeek; // 1=Mon .. 7=Sun
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;
  final String color;

  const TimetableEntry({
    required this.id,
    required this.userId,
    required this.subject,
    required this.instructor,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.color,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> j) {
    final st = (j['start_time'] as String? ?? '09:00').split(':');
    final et = (j['end_time'] as String? ?? '10:00').split(':');
    return TimetableEntry(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      subject: j['subject'] as String? ?? '',
      instructor: j['instructor'] as String? ?? '',
      dayOfWeek: j['day_of_week'] as int? ?? 1,
      startTime: TimeOfDay(
          hour: int.tryParse(st[0]) ?? 9, minute: int.tryParse(st[1]) ?? 0),
      endTime: TimeOfDay(
          hour: int.tryParse(et[0]) ?? 10, minute: int.tryParse(et[1]) ?? 0),
      room: j['room'] as String? ?? '',
      color: j['color'] as String? ?? '#5B8FF9',
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'subject': subject,
        'instructor': instructor,
        'day_of_week': dayOfWeek,
        'start_time':
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        'room': room,
        'color': color,
      };
}

final timetableProvider =
    FutureProvider.autoDispose<List<TimetableEntry>>((ref) async {
  final uid = SupabaseConfig.auth.currentUser?.id;
  if (uid == null) return [];
  try {
    final data = await SupabaseConfig.client
        .from('timetable')
        .select()
        .eq('user_id', uid)
        .order('day_of_week')
        .order('start_time');
    return (data as List).map((j) => TimetableEntry.fromJson(j)).toList();
  } catch (_) {
    return [];
  }
});

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});
  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedDay = DateTime.now().weekday; // 1=Mon

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _colors = [
    '#5B8FF9',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#00D4FF',
    '#7B6FEF',
    '#EC4899'
  ];

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _addEntry() async {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    final subject = TextEditingController();
    final room = TextEditingController();
    final instructor = TextEditingController();
    int day = _selectedDay;
    TimeOfDay startT = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endT = const TimeOfDay(hour: 10, minute: 0);
    String color = _colors[0];

    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (ctx, ss) => AlertDialog(
                backgroundColor: AppColors.darkCard,
                title: const Text('Add Class',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _field(subject, 'Subject'),
                  const SizedBox(height: 12),
                  _field(instructor, 'Instructor'),
                  const SizedBox(height: 12),
                  _field(room, 'Room'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: day,
                    decoration: _inputDec('Day'),
                    dropdownColor: AppColors.darkSecondary,
                    style: const TextStyle(color: Colors.white),
                    items: List.generate(
                        7,
                        (i) => DropdownMenuItem(
                            value: i + 1, child: Text(_days[i]))),
                    onChanged: (v) => ss(() => day = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: startT);
                        if (t != null) ss(() => startT = t);
                      },
                      child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.darkSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.darkBorder)),
                          child: Text(startT.format(ctx),
                              style: const TextStyle(color: Colors.white))),
                    )),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('→',
                            style: TextStyle(color: AppColors.darkMuted))),
                    Expanded(
                        child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: endT);
                        if (t != null) ss(() => endT = t);
                      },
                      child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.darkSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.darkBorder)),
                          child: Text(endT.format(ctx),
                              style: const TextStyle(color: Colors.white))),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      children: _colors.map((c) {
                        final col = _parseColor(c);
                        return GestureDetector(
                          onTap: () => ss(() => color = c),
                          child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: color == c
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2))),
                        );
                      }).toList()),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.darkMuted))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () async {
                      if (subject.text.trim().isEmpty) return;
                      try {
                        await SupabaseConfig.client.from('timetable').insert({
                          'user_id': uid,
                          'subject': subject.text.trim(),
                          'instructor': instructor.text.trim(),
                          'day_of_week': day,
                          'start_time':
                              '${startT.hour.toString().padLeft(2, '0')}:${startT.minute.toString().padLeft(2, '0')}',
                          'end_time':
                              '${endT.hour.toString().padLeft(2, '0')}:${endT.minute.toString().padLeft(2, '0')}',
                          'room': room.text.trim(),
                          'color': color,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.invalidate(timetableProvider);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.danger));
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ));
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.darkMuted),
        filled: true,
        fillColor: AppColors.darkSecondary,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder)),
      );

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDec(label),
      );

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(timetableProvider);
    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Timetable',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _addEntry,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Class',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        // Day selector
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: 7,
            itemBuilder: (_, i) {
              final d = i + 1;
              final selected = d == _selectedDay;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = d),
                child: Container(
                  width: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                    color: selected ? AppColors.primary : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.darkBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(_days[i],
                      style: TextStyle(
                          color: selected ? Colors.white : AppColors.darkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: timetableAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (entries) {
              final dayEntries =
                  entries.where((e) => e.dayOfWeek == _selectedDay).toList();
              if (dayEntries.isEmpty) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Icon(Icons.calendar_today,
                          size: 48, color: AppColors.darkMuted),
                      const SizedBox(height: 12),
                      Text('No classes on ${_days[_selectedDay - 1]}',
                          style: const TextStyle(color: AppColors.darkMuted)),
                      const SizedBox(height: 8),
                      const Text('Tap + to add a class',
                          style: TextStyle(
                              color: AppColors.darkMuted, fontSize: 12)),
                    ]));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dayEntries.length,
                itemBuilder: (_, i) {
                  final e = dayEntries[i];
                  final color = _parseColor(e.color);
                  return Dismissible(
                    key: Key(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.danger,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await SupabaseConfig.client
                          .from('timetable')
                          .delete()
                          .eq('id', e.id);
                      ref.invalidate(timetableProvider);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border(left: BorderSide(color: color, width: 4)),
                      ),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(e.subject,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              if (e.instructor.isNotEmpty)
                                Text(e.instructor,
                                    style: const TextStyle(
                                        color: AppColors.darkMuted,
                                        fontSize: 12)),
                              if (e.room.isNotEmpty)
                                Text('📍 ${e.room}',
                                    style: const TextStyle(
                                        color: AppColors.darkMuted,
                                        fontSize: 12)),
                            ])),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(e.startTime.format(context),
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(e.endTime.format(context),
                                  style: const TextStyle(
                                      color: AppColors.darkMuted,
                                      fontSize: 12)),
                            ]),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
