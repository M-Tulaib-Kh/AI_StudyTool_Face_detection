// ============================================================
// StudyLock — Student Ranking & Leaderboard Screen
// Fixed: N+1 query → single JOIN query
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class RankingEntry {
  final int rank;
  final String userId;
  final String name;
  final String department;
  final int totalPoints;
  final int streak;
  const RankingEntry({
    required this.rank, required this.userId, required this.name,
    required this.department, required this.totalPoints, required this.streak,
  });
}

final rankingProvider = FutureProvider.autoDispose<List<RankingEntry>>((ref) async {
  try {
    // Single JOIN query — no N+1 problem
    final data = await SupabaseConfig.client
        .from('game_state')
        .select('user_id, points, streak, profiles!inner(full_name, department)')
        .order('points', ascending: false)
        .limit(50);

    int rank = 1;
    return (data as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>? ?? {};
      return RankingEntry(
        rank: rank++,
        userId: row['user_id'] as String,
        name: profile['full_name'] as String? ?? 'Student',
        department: profile['department'] as String? ?? '',
        totalPoints: (row['points'] as int?) ?? 0,
        streak: (row['streak'] as int?) ?? 0,
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);
    final currentUser = ref.watch(currentUserProvider);

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.invalidate(rankingProvider),
          ),
        ],
      ),
      body: rankingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.leaderboard, size: 64, color: AppColors.darkMuted),
                SizedBox(height: 12),
                Text('No rankings yet', style: TextStyle(color: AppColors.darkMuted, fontSize: 16)),
                SizedBox(height: 8),
                Text('Complete study sessions to earn points!',
                    style: TextStyle(color: AppColors.darkMuted, fontSize: 13)),
              ]),
            );
          }
          return CustomScrollView(
            slivers: [
              if (entries.length >= 3)
                SliverToBoxAdapter(child: _Podium(top3: entries.take(3).toList())),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final e = entries[i];
                      return _RankCard(entry: e, isMe: e.userId == currentUser?.id);
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<RankingEntry> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.warning, AppColors.darkForeground, AppColors.accent];
    final heights = [120.0, 90.0, 70.0];
    final order = [1, 0, 2];

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((idx) {
          if (idx >= top3.length) return const SizedBox.shrink();
          final e = top3[idx];
          final color = colors[idx];
          final height = heights[idx];
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(e.name.split(' ').first,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color, width: 2)),
                alignment: Alignment.center,
                child: Text('${e.rank}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(height: 4),
              Text('${e.totalPoints} pts',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                width: 80, height: height,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(e.rank == 1 ? '🥇' : e.rank == 2 ? '🥈' : '🥉',
                    style: const TextStyle(fontSize: 24)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final RankingEntry entry;
  final bool isMe;
  const _RankCard({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final medal = entry.rank == 1
        ? '🥇'
        : entry.rank == 2
            ? '🥈'
            : entry.rank == 3
                ? '🥉'
                : '#${entry.rank}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(boxShadow: AppShadows.clay, 
        color: isMe ? AppColors.primary.withValues(alpha: 0.12) : AppColors.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isMe ? AppColors.primary.withValues(alpha: 0.4) : AppColors.darkBorder),
      ),
      child: Row(children: [
        SizedBox(
            width: 36,
            child: Text(medal,
                style: const TextStyle(fontSize: 18), textAlign: TextAlign.center)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(entry.name,
                style: TextStyle(
                    color: isMe ? AppColors.primary : AppColors.darkForeground,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('You',
                    style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
              )
            ],
          ]),
          if (entry.department.isNotEmpty)
            Text(entry.department,
                style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${entry.totalPoints} pts',
              style: const TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 14)),
          if (entry.streak > 0)
            Text('🔥 ${entry.streak}d',
                style: const TextStyle(color: AppColors.accent, fontSize: 11)),
        ]),
      ]),
    );
  }
}
