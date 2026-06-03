// ignore_for_file: unnecessary_cast

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../data/models/models.dart';

class GameNotifier extends StateNotifier<GameState?> {
  GameNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseConfig.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await SupabaseConfig.client
          .from('game_state')
          .select()
          .eq('user_id', uid)
          .single();
      state = GameState.fromJson(data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _save() async {
    final s = state;
    if (s == null) return;
    try {
      await SupabaseConfig.client
          .from('game_state')
          .upsert(s.toUpdateJson())
          .eq('user_id', s.userId);
    } catch (_) {}
  }

  Future<void> addPoints(int amount) async {
    if (state == null || amount <= 0) return;
    state = GameState(
        userId: state!.userId,
        points: state!.points + amount,
        streak: state!.streak,
        longestStreak: state!.longestStreak,
        lastSessionDate: state!.lastSessionDate,
        badges: state!.badges,
        challenges: state!.challenges);
    await _save();
  }

  Future<void> checkAndUpdateStreak(DateTime now) async {
    final s = state;
    if (s == null) return;
    final today = DateTime(now.year, now.month, now.day);
    if (s.lastSessionDate != null) {
      final last = DateTime(s.lastSessionDate!.year, s.lastSessionDate!.month,
          s.lastSessionDate!.day);
      if (last == today) return;
    }
    final diff = s.lastSessionDate == null
        ? 999
        : today
            .difference(DateTime(s.lastSessionDate!.year,
                s.lastSessionDate!.month, s.lastSessionDate!.day))
            .inDays;
    final newStreak = diff <= 1 ? s.streak + 1 : 1;
    final longest = newStreak > s.longestStreak ? newStreak : s.longestStreak;
    state = GameState(
        userId: s.userId,
        points: s.points,
        streak: newStreak,
        longestStreak: longest,
        lastSessionDate: today,
        badges: s.badges,
        challenges: s.challenges);
    if (newStreak >= 3) unlockBadge('streak_3');
    if (newStreak >= 7) unlockBadge('streak_7');
    await _save();
  }

  Future<void> unlockBadge(String id) async {
    final s = state;
    if (s == null) return;
    final updated = s.badges
        .map((b) => b.id == id && !b.unlocked
            ? b.copyWith(unlocked: true, unlockedAt: DateTime.now())
            : b)
        .toList();
    state = GameState(
        userId: s.userId,
        points: s.points,
        streak: s.streak,
        longestStreak: s.longestStreak,
        lastSessionDate: s.lastSessionDate,
        badges: updated,
        challenges: s.challenges);
    await _save();
  }

  Future<void> updateChallenge(String id, int progress) async {
    final s = state;
    if (s == null) return;
    final updated = s.challenges.map((c) {
      if (c.id != id) return c;
      final nc = (c.current + progress).clamp(0, c.target);
      final done = nc >= c.target;
      if (done && !c.completed) addPoints(c.reward);
      return c.copyWith(current: nc, completed: done);
    }).toList();
    state = GameState(
        userId: s.userId,
        points: s.points,
        streak: s.streak,
        longestStreak: s.longestStreak,
        lastSessionDate: s.lastSessionDate,
        badges: s.badges,
        challenges: updated);
    await _save();
  }
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameState?>((ref) => GameNotifier());
