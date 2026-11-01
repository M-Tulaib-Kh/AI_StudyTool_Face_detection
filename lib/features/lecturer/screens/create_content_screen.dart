import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_provider.dart';
import '../../../data/models/models.dart';
import '../../../services/storage_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../services/ai_service.dart';

class CreateContentScreen extends ConsumerStatefulWidget {
  final String type; // 'lecture' | 'assignment' | 'quiz'
  const CreateContentScreen({super.key, required this.type});
  @override
  ConsumerState<CreateContentScreen> createState() =>
      _CreateContentScreenState();
}

class _CreateContentScreenState extends ConsumerState<CreateContentScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _desc = TextEditingController();
  final _instructions = TextEditingController();
  final _aiPrompt = TextEditingController();
  final _quizCount = TextEditingController(text: '5');
  final _duration = TextEditingController(text: '15');
  final _totalMarks = TextEditingController(text: '100');
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  String? _courseId;
  bool _loading = false;
  bool _aiMode = false;
  bool _aiGenerating = false;
  double _uploadProgress = 0;
  String? _uploadedFileUrl, _uploadedFileName;

  @override
  void dispose() {
    for (final c in [
      _title,
      _subject,
      _desc,
      _instructions,
      _aiPrompt,
      _quizCount,
      _duration,
      _totalMarks
    ]) c.dispose();
    super.dispose();
  }

  String get _typeLabel => switch (widget.type) {
        'assignment' => 'Assignment',
        'quiz' => 'Quiz',
        _ => 'Lecture'
      };

  Future<void> _pickAndUploadFile() async {
    final file = await StorageService.pickFile(
        extensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx']);
    if (file == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _uploadProgress = 0;
      _uploadedFileName = file.name;
    });
    try {
      final bucket = widget.type == 'assignment'
          ? StorageBucket.assignmentFiles
          : StorageBucket.lectureFiles;
      final result = await StorageService.uploadFile(
          file: file,
          bucket: bucket,
          userId: user.id,
          onProgress: (p) => setState(() => _uploadProgress = p));
      setState(() {
        _uploadedFileUrl = result.fileUrl;
        _uploadedFileName = file.name;
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('File uploaded!'),
            backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.danger));
      setState(() {
        _uploadedFileUrl = null;
        _uploadedFileName = null;
      });
    }
  }

  Future<void> _generateWithAI() async {
    if (_subject.text.trim().isEmpty || _aiPrompt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter subject and prompt first')));
      return;
    }
    setState(() => _aiGenerating = true);
    try {
      if (widget.type == 'assignment') {
        final r = await AiService.instance.generateAssignment(
            subject: _subject.text.trim(), prompt: _aiPrompt.text.trim());
        if (mounted) {
          setState(() {
            _title.text = r.title;
            _desc.text = r.description;
            _instructions.text = r.instructions;
          });
        }
      } else if (widget.type == 'quiz') {
        final count = int.tryParse(_quizCount.text) ?? 5;
        final qs = await AiService.instance.generateQuiz(
            subject: _subject.text.trim(),
            prompt: _aiPrompt.text.trim(),
            count: count);
        if (mounted) {
          setState(() {
            _title.text =
                '${_subject.text} Quiz — ${_aiPrompt.text.substring(0, _aiPrompt.text.length.clamp(0, 30))}';
          });
          _generatedQuestions = qs;
        }
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('AI generated content!'),
            backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('AI error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _aiGenerating = false);
    }
  }

  List<QuizQuestion> _generatedQuestions = [];

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final state = ref.read(academicProvider);
      final courses =
          state.courses.where((c) => c.lecturerId == user.id).toList();
      final cid = _courseId ?? (courses.isNotEmpty ? courses.first.id : null);

      if (widget.type == 'lecture') {
        if (_uploadedFileUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please upload a file')));
          setState(() => _loading = false);
          return;
        }
        await ref.read(academicProvider.notifier).createLecture(
            courseId: cid ?? '',
            title: _title.text.trim(),
            subject: _subject.text.trim(),
            description: _desc.text.trim(),
            fileUrl: _uploadedFileUrl!,
            fileName: _uploadedFileName ?? '',
            uploadedBy: user.id);
      } else if (widget.type == 'assignment') {
        await ref.read(academicProvider.notifier).createAssignment(
            courseId: cid ?? '',
            title: _title.text.trim(),
            subject: _subject.text.trim(),
            description: _desc.text.trim(),
            instructions: _instructions.text.trim(),
            deadline: _deadline,
            totalMarks: int.tryParse(_totalMarks.text) ?? 100,
            createdBy: user.id,
            aiGenerated: _aiMode,
            fileUrl: _uploadedFileUrl ?? '',
            fileName: _uploadedFileName ?? '');
      } else if (widget.type == 'quiz') {
        final questions = _generatedQuestions.isNotEmpty
            ? _generatedQuestions
            : <QuizQuestion>[];
        if (questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Generate questions with AI first')));
          setState(() => _loading = false);
          return;
        }
        await ref.read(academicProvider.notifier).createQuiz(
            courseId: cid ?? '',
            title: _title.text.trim(),
            subject: _subject.text.trim(),
            description: _desc.text.trim(),
            questions: questions,
            durationMinutes: int.tryParse(_duration.text) ?? 15,
            createdBy: user.id,
            aiGenerated: _aiMode);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$_typeLabel created!'),
            backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academicProvider);
    final user = ref.watch(currentUserProvider);
    final myCourses =
        state.courses.where((c) => c.lecturerId == user?.id).toList();

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop()),
        title: Text('Create $_typeLabel',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Course selector
              if (myCourses.isNotEmpty) ...[
                _label('Course'),
                DropdownButtonFormField<String>(
                  initialValue: _courseId,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Select course'),
                  items: myCourses
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.title)))
                      .toList(),
                  onChanged: (v) => setState(() => _courseId = v),
                ),
                const SizedBox(height: 16),
              ],

              // AI Toggle for assignment/quiz
              if (widget.type != 'lecture') ...[
                Row(children: [
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('AI Generation',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        Text('Let AI create the content for you',
                            style: TextStyle(
                                color: AppColors.darkMuted, fontSize: 12)),
                      ])),
                  Switch(
                      value: _aiMode,
                      onChanged: (v) => setState(() => _aiMode = v),
                      activeThumbColor: AppColors.primary),
                ]),
                const SizedBox(height: 12),
              ],

              // AI Prompt section
              if (_aiMode && widget.type != 'lecture') ...[
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.auto_awesome,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Text('AI Generator',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600))
                          ]),
                          const SizedBox(height: 12),
                          _label('Subject'),
                          TextFormField(
                              controller: _subject,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  hintText: 'e.g. Computer Science')),
                          const SizedBox(height: 10),
                          _label('Prompt / Topic'),
                          TextFormField(
                              controller: _aiPrompt,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2,
                              decoration: const InputDecoration(
                                  hintText:
                                      'e.g. Data structures and algorithms')),
                          if (widget.type == 'quiz') ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    _label('No. of Questions'),
                                    TextFormField(
                                        controller: _quizCount,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            hintText: '5')),
                                  ])),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    _label('Duration (min)'),
                                    TextFormField(
                                        controller: _duration,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            hintText: '15')),
                                  ])),
                            ]),
                          ],
                          const SizedBox(height: 12),
                          AppButton(
                              label: _aiGenerating
                                  ? 'Generating...'
                                  : 'Generate with AI',
                              loading: _aiGenerating,
                              icon: Icons.auto_awesome,
                              onTap: _generateWithAI),
                          if (_generatedQuestions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${_generatedQuestions.length} questions generated',
                                      style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600)),
                                ])),
                          ],
                        ])),
                const SizedBox(height: 16),
              ],

              // Manual fields
              _label('Title'),
              TextFormField(
                  controller: _title,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      InputDecoration(hintText: 'Enter $_typeLabel title'),
                  validator: (v) =>
                      (v?.trim().length ?? 0) > 2 ? null : 'Required'),
              const SizedBox(height: 14),

              if (!_aiMode || widget.type == 'lecture') ...[
                _label('Subject'),
                TextFormField(
                    controller: _subject,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(hintText: 'e.g. Mathematics')),
                const SizedBox(height: 14),
              ],

              _label('Description'),
              TextFormField(
                  controller: _desc,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Brief description')),
              const SizedBox(height: 14),

              // Assignment-specific
              if (widget.type == 'assignment') ...[
                _label('Instructions'),
                TextFormField(
                    controller: _instructions,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                        hintText: 'Detailed instructions for students')),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _label('Total Marks'),
                        TextFormField(
                            controller: _totalMarks,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '100')),
                      ])),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _label('Deadline'),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                                context: context,
                                initialDate: _deadline,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)));
                            if (d != null) setState(() => _deadline = d);
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                  color: AppColors.darkSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.darkBorder)),
                              child: Text(
                                  '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14))),
                        ),
                      ])),
                ]),
                const SizedBox(height: 14),
              ],

              // File upload for lecture/assignment
              if (widget.type == 'lecture' || widget.type == 'assignment') ...[
                _label(widget.type == 'lecture'
                    ? 'Lecture File (PDF/PPT)'
                    : 'Reference File (Optional)'),
                GestureDetector(
                  onTap: _pickAndUploadFile,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                        color: _uploadedFileUrl != null
                            ? AppColors.success.withValues(alpha: 0.08)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: _uploadedFileUrl != null
                                ? AppColors.success.withValues(alpha: 0.4)
                                : AppColors.darkBorder,
                            style: BorderStyle.solid)),
                    child: Row(children: [
                      Icon(
                          _uploadedFileUrl != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: _uploadedFileUrl != null
                              ? AppColors.success
                              : AppColors.darkMuted,
                          size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                _uploadedFileUrl != null
                                    ? 'File uploaded'
                                    : 'Tap to choose file',
                                style: TextStyle(
                                    color: _uploadedFileUrl != null
                                        ? AppColors.success
                                        : Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text(
                                _uploadedFileName ??
                                    'PDF, DOC, DOCX, PPT supported',
                                style: const TextStyle(
                                    color: AppColors.darkMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ])),
                    ]),
                  ),
                ),
                if (_uploadProgress > 0 && _uploadProgress < 1) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: _uploadProgress,
                      color: AppColors.primary,
                      backgroundColor: AppColors.darkBorder,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4)),
                ],
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 8),
              AppButton(
                  label: 'Create $_typeLabel',
                  loading: _loading,
                  onTap: _submit),
              const SizedBox(height: 40),
            ])),
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)));
}
