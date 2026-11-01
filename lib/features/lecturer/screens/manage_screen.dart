import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/empty_state.dart';

class ManageScreen extends ConsumerStatefulWidget {
  const ManageScreen({super.key});
  @override
  ConsumerState<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends ConsumerState<ManageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(academicProvider);
    final uid = user?.id ?? '';
    // ignore: unused_local_variable
    final myCourses = state.courses
        .where((c) => c.lecturerId == uid)
        .map((c) => c.id)
        .toSet();
    final myLectures =
        state.lectures.where((l) => l.uploadedBy == uid).toList();
    final myAssignments =
        state.assignments.where((a) => a.createdBy == uid).toList();
    final myQuizzes = state.quizzes.where((q) => q.createdBy == uid).toList();
    final assignIds = myAssignments.map((a) => a.id).toSet();
    final mySubs = state.submissions
        .where((s) => assignIds.contains(s.assignmentId))
        .toList();

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showCreateMenu(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkMuted,
          tabs: [
            Tab(text: 'Lectures (${myLectures.length})'),
            Tab(text: 'Assignments (${myAssignments.length})'),
            Tab(text: 'Quizzes (${myQuizzes.length})'),
            Tab(text: 'Submissions (${mySubs.length})'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Padding(padding: EdgeInsets.all(16), child: ShimmerList())
          : TabBarView(
              controller: _tabs,
              children: [
                _LecturesList(items: myLectures),
                _AssignmentsList(items: myAssignments),
                _QuizzesList(items: myQuizzes),
                _SubmissionsList(items: mySubs, assignments: myAssignments),
              ],
            ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Create New',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _SheetItem(Icons.upload_file, 'Upload Lecture', AppColors.primary,
              () {
            Navigator.pop(context);
            context.push('/create-content?type=lecture');
          }),
          _SheetItem(
              Icons.assignment_add, 'Create Assignment', AppColors.accent, () {
            Navigator.pop(context);
            context.push('/create-content?type=assignment');
          }),
          _SheetItem(Icons.quiz_outlined, 'Create Quiz', AppColors.warning, () {
            Navigator.pop(context);
            context.push('/create-content?type=quiz');
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetItem(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        title: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.darkMuted),
        onTap: onTap,
      );
}

class _LecturesList extends StatelessWidget {
  final List<Lecture> items;
  const _LecturesList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
          icon: Icons.library_books_outlined,
          title: 'No Lectures Yet',
          subtitle: 'Upload your first lecture');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final l = items[i];
        return _Card(
          icon: Icons.library_books,
          iconColor: AppColors.primary,
          title: l.title,
          sub: l.subject,
          trailing: l.fileUrl.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.visibility,
                      color: AppColors.accent, size: 20),
                  onPressed: () => _viewPdf(context, l.fileUrl, l.title))
              : null,
        );
      },
    );
  }

  void _viewPdf(BuildContext context, String url, String title) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _PdfViewer(url: url, title: title)));
  }
}

class _PdfViewer extends StatelessWidget {
  final String url, title;
  const _PdfViewer({required this.url, required this.title});
  @override
  Widget build(BuildContext context) => ClayScaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.darkCard,
          title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis),
          leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: SfPdfViewer.network(url),
      );
}

class _AssignmentsList extends StatelessWidget {
  final List<Assignment> items;
  const _AssignmentsList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
          icon: Icons.assignment_outlined,
          title: 'No Assignments Yet',
          subtitle: 'Create your first assignment');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = items[i];
        return _Card(
          icon: Icons.assignment,
          iconColor: AppColors.accent,
          title: a.title,
          sub:
              '${a.subject} · Due ${a.daysUntilDeadline}d · ${a.totalMarks} marks',
          tag: a.aiGenerated ? 'AI' : null,
        );
      },
    );
  }
}

class _QuizzesList extends StatelessWidget {
  final List<Quiz> items;
  const _QuizzesList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No Quizzes Yet',
          subtitle: 'Create your first quiz');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final q = items[i];
        return _Card(
          icon: Icons.quiz,
          iconColor: AppColors.warning,
          title: q.title,
          sub:
              '${q.subject} · ${q.questions.length} questions · ${q.durationMinutes}min',
          tag: q.aiGenerated ? 'AI' : null,
        );
      },
    );
  }
}

class _SubmissionsList extends ConsumerWidget {
  final List<Submission> items;
  final List<Assignment> assignments;
  const _SubmissionsList({required this.items, required this.assignments});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No Submissions Yet',
          subtitle: 'Student submissions will appear here');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = items[i];
        final assign =
            assignments.where((a) => a.id == s.assignmentId).firstOrNull;
        final isGraded = s.status == SubmissionStatus.graded;
        return _Card(
          icon: Icons.description,
          iconColor: isGraded ? AppColors.success : AppColors.warning,
          title: s.studentName,
          sub: assign?.title ?? 'Assignment',
          tag: isGraded ? 'Graded' : 'Pending',
          tagColor: isGraded ? AppColors.success : AppColors.warning,
          trailing: IconButton(
            icon: const Icon(Icons.grading, color: AppColors.primary, size: 22),
            onPressed: () => context.push('/grade-submission/${s.id}'),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, sub;
  final String? tag;
  final Color? tagColor;
  final Widget? trailing;
  const _Card(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.sub,
      this.tag,
      this.tagColor,
      this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(boxShadow: AppShadows.clay, 
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.darkBorder)),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  if (tag != null)
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: (tagColor ?? AppColors.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(tag!,
                            style: TextStyle(
                                color: tagColor ?? AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 3),
                Text(sub,
                    style: const TextStyle(
                        color: AppColors.darkMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
          if (trailing != null) trailing!,
        ]),
      );
}
