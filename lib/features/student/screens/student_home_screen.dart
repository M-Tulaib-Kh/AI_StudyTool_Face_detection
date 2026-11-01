import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/hero_banner.dart';
import '../widgets/focus_insights_card.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(academicProvider);
    // ignore: unused_local_variable
    final session = ref.watch(sessionProvider);
    final game = ref.watch(gameProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(academicProvider.notifier).loadAll(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('$greeting 👋',
                                style: const TextStyle(
                                    color: AppColors.darkMuted, fontSize: 13)),
                            Text(user?.fullName.split(' ').first ?? 'Student',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900)),
                          ])),
                      Row(children: [
                        if (game != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star,
                                  color: AppColors.warning, size: 14),
                              const SizedBox(width: 4),
                              Text('${game.points}',
                                  style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ]),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () => context.push('/settings'),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 4),
                    if (user?.department != null)
                      Text(user!.department!,
                          style: const TextStyle(
                              color: AppColors.darkMuted, fontSize: 12)),
                  ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Hero banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HeroBanner(
                title: 'Stay focused,\nlevel up every day',
                subtitle: 'Start a session, keep your streak and earn rewards.',
                asset: 'assets/images/hero_study.png',
                actionLabel: 'Start focusing',
                onTap: () => context.go('/student/session'),
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Study session CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SessionCta(onTap: () => context.go('/student/session'))
                  .animate()
                  .fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Focus insights (daily goal ring, 14-day heat strip)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const FocusInsightsCard()
                  .animate()
                  .fadeIn(duration: 450.ms, delay: 80.ms)
                  .slideY(begin: 0.06),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Quick Actions grid (2 rows of 4)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                      children: [
                        _QuickBtn(
                            'Attendance',
                            Icons.event_note_outlined,
                            AppColors.success,
                            () => context.push('/attendance')),
                        _QuickBtn('GPA', Icons.school_outlined,
                            AppColors.primary, () => context.push('/gpa')),
                        _QuickBtn('Ranking', Icons.leaderboard,
                            AppColors.warning, () => context.push('/ranking')),
                        _QuickBtn('AI Tutor', Icons.auto_awesome,
                            AppColors.accent, () => context.push('/ai-tutor')),
                        _QuickBtn(
                            'Timetable',
                            Icons.calendar_today,
                            AppColors.success,
                            () => context.push('/timetable')),
                        _QuickBtn(
                            'Analytics',
                            Icons.bar_chart,
                            AppColors.primary,
                            () => context.push('/analytics')),
                        _QuickBtn('Report', Icons.assessment, AppColors.warning,
                            () => context.push('/attendance-report')),
                        _QuickBtn(
                            'Settings',
                            Icons.settings_outlined,
                            AppColors.darkMuted,
                            () => context.push('/settings')),
                      ],
                    ),
                  ]),
            ).animate().fadeIn(delay: 200.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Upcoming assignments
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                  title: 'Upcoming Assignments',
                  onSeeAll: () => context.go('/student/academic')),
            ),
          ),
          if (state.isLoading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ShimmerLoader(height: 90, borderRadius: 14)))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                final pending = state.assignments
                    .where((a) => !a.isOverdue)
                    .take(3)
                    .toList();
                if (pending.isEmpty) {
                  return const _EmptyCard('No upcoming assignments');
                }
                if (i >= pending.length) return null;
                return _AssignCard(
                    a: pending[i],
                    onTap: () => context.push('/assignment/${pending[i].id}'));
              },
                      childCount: state.assignments
                              .where((a) => !a.isOverdue)
                              .take(3)
                              .isEmpty
                          ? 1
                          : state.assignments
                              .where((a) => !a.isOverdue)
                              .take(3)
                              .length)),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Recent lectures
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                  title: 'Recent Lectures',
                  onSeeAll: () => context.go('/student/academic')),
            ),
          ),
          if (state.isLoading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ShimmerLoader(height: 80, borderRadius: 14)))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                final lectures = state.lectures.take(3).toList();
                if (lectures.isEmpty) {
                  return const _EmptyCard('No lectures yet');
                }
                if (i >= lectures.length) return null;
                final l = lectures[i];
                return _LectureCard(
                    l: l, onTap: () => context.push('/lecture/${l.id}'));
              },
                      childCount: state.lectures.take(3).isEmpty
                          ? 1
                          : state.lectures.take(3).length)),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25))),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}

class _SessionCta extends StatelessWidget {
  final VoidCallback onTap;
  const _SessionCta({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF7B6FEF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.play_circle_outline,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Start Study Session',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text('Focus with AI monitoring',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ]),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          TextButton(
              onPressed: onSeeAll,
              child: const Text('See All',
                  style: TextStyle(color: AppColors.primary, fontSize: 12))),
        ]),
      );
}

class _AssignCard extends StatelessWidget {
  final Assignment a;
  final VoidCallback onTap;
  const _AssignCard({required this.a, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final daysLeft = a.daysUntilDeadline;
    final urgency = daysLeft <= 1
        ? AppColors.danger
        : daysLeft <= 3
            ? AppColors.warning
            : AppColors.success;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(boxShadow: AppShadows.clay, 
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(22),
          border: Border(left: BorderSide(color: urgency, width: 3)),
        ),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(a.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${a.subject} • ${DateFormat('dd MMM').format(a.deadline)}',
                    style: const TextStyle(
                        color: AppColors.darkMuted, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: urgency.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(daysLeft == 0 ? 'Today!' : '$daysLeft days',
                style: TextStyle(
                    color: urgency, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _LectureCard extends StatelessWidget {
  final Lecture l;
  final VoidCallback onTap;
  const _LectureCard({required this.l, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(boxShadow: AppShadows.clay, 
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.darkBorder)),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${l.subject} • ${l.views} views',
                      style: const TextStyle(
                          color: AppColors.darkMuted, fontSize: 12)),
                ])),
            const Icon(Icons.open_in_new, color: AppColors.darkMuted, size: 16),
          ]),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  final String msg;
  const _EmptyCard(this.msg);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(boxShadow: AppShadows.clay, 
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.darkBorder)),
        child: Center(
            child: Text(msg,
                style:
                    const TextStyle(color: AppColors.darkMuted, fontSize: 13))),
      );
}
