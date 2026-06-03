import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../data/models/models.dart';

class SessionState {
  final StudySession? activeSession;
  final List<StudySession> sessions;
  final int elapsedSeconds;
  const SessionState(
      {this.activeSession, this.sessions = const [], this.elapsedSeconds = 0});
  int get totalStudySeconds => sessions
      .where((s) => s.validSession)
      .fold(0, (a, s) => a + s.elapsedSeconds);
  int get todaySeconds {
    final start = DateTime.now();
    final today = DateTime(start.year, start.month, start.day);
    return sessions
        .where((s) => s.validSession && s.startedAt.isAfter(today))
        .fold(0, (a, s) => a + s.elapsedSeconds);
  }

  int get weekSeconds {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final ws = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return sessions
        .where((s) => s.validSession && s.startedAt.isAfter(ws))
        .fold(0, (a, s) => a + s.elapsedSeconds);
  }

  SessionState copyWith(
          {StudySession? activeSession,
          List<StudySession>? sessions,
          int? elapsedSeconds,
          bool clearActive = false}) =>
      SessionState(
        activeSession:
            clearActive ? null : (activeSession ?? this.activeSession),
        sessions: sessions ?? this.sessions,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState()) {
    _load();
  }
  Timer? _timer;

  Future<void> _load() async {
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await SupabaseConfig.client
          .from('study_sessions')
          .select()
          .eq('user_id', uid)
          .order('started_at', ascending: false)
          .limit(100);
      final sessions =
          (data as List).map((j) => StudySession.fromJson(j)).toList();
      // Restore active session if app was killed mid-session
      final active =
          sessions.where((s) => s.status == SessionStatus.active).firstOrNull;
      state = state.copyWith(
          sessions: sessions,
          activeSession: active,
          elapsedSeconds: active?.elapsedSeconds ?? 0);
      if (active != null) _startTimer();
    } catch (_) {}
  }

  Future<void> startSession(
      {required int plannedDurationSeconds,
      required List<String> blockedApps,
      required bool cameraEnabled}) async {
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) return;
    final data = await SupabaseConfig.client
        .from('study_sessions')
        .insert({
          'user_id': uid,
          'planned_duration_seconds': plannedDurationSeconds,
          'camera_enabled': cameraEnabled,
          'blocked_apps': blockedApps,
          'status': 'active',
        })
        .select()
        .single();
    // ignore: unnecessary_cast
    final session = StudySession.fromJson(data as Map<String, dynamic>);
    state = state.copyWith(activeSession: session, elapsedSeconds: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      // Persist every 30s
      if (state.elapsedSeconds % 30 == 0) _persistElapsed();
    });
  }

  void _persistElapsed() {
    final s = state.activeSession;
    if (s == null) return;
    SupabaseConfig.client
        .from('study_sessions')
        .update({'elapsed_seconds': state.elapsedSeconds})
        .eq('id', s.id)
        .ignore();
  }

  void recordViolation() {
    final s = state.activeSession;
    if (s == null) return;
    final newViolations = s.violations + 1;
    state = state.copyWith(
        activeSession: StudySession(
      id: s.id,
      userId: s.userId,
      plannedDurationSeconds: s.plannedDurationSeconds,
      elapsedSeconds: s.elapsedSeconds,
      status: s.status,
      violations: newViolations,
      cameraEnabled: s.cameraEnabled,
      validSession: s.validSession,
      blockedApps: s.blockedApps,
      startedAt: s.startedAt,
    ));
    SupabaseConfig.client
        .from('study_sessions')
        .update({'violations': newViolations})
        .eq('id', s.id)
        .ignore();
  }

  Future<void> endSession(SessionStatus status) async {
    _timer?.cancel();
    _timer = null;
    final s = state.activeSession;
    if (s == null) return;
    final isValid = status == SessionStatus.completed && s.violations < 3;
    await SupabaseConfig.client.from('study_sessions').update({
      'status': status.name,
      'elapsed_seconds': state.elapsedSeconds,
      'valid_session': isValid,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', s.id);
    await _load();
    state = state.copyWith(clearActive: true, elapsedSeconds: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
    (ref) => SessionNotifier());
