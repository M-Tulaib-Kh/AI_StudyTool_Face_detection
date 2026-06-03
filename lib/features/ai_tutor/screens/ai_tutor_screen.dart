// ============================================================
// StudyLock — AI Chat Tutor Screen
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/gemini_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  const _ChatMessage({required this.text, required this.isUser, required this.time});
}

class AITutorScreen extends ConsumerStatefulWidget {
  const AITutorScreen({super.key});
  @override ConsumerState<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends ConsumerState<AITutorScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatMessage>[
    _ChatMessage(text: 'Hello! I\'m your AI Study Tutor 🎓\nAsk me anything about your subjects, get explanations, solve problems, or request study tips!', isUser: false, time: DateTime.now()),
  ];
  bool _thinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thinking) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final result = await GeminiService.instance.generateAssignment(
        subject: 'Academic Tutoring',
        prompt: 'As a helpful academic tutor, answer this student question clearly and concisely:\n\n$text\n\nProvide a clear explanation with examples if needed. Keep response under 300 words.',
      );
      final response = result.description.isNotEmpty ? result.description : result.instructions;
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response.isEmpty ? 'I couldn\'t generate a response. Please try again.' : response, isUser: false, time: DateTime.now()));
          _thinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: 'Sorry, I encountered an error. Please check your connection and try again.', isUser: false, time: DateTime.now()));
          _thinking = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]), shape: BoxShape.circle),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Tutor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Powered by Gemini', style: TextStyle(color: AppColors.darkMuted, fontSize: 11)),
          ]),
        ]),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Clear chat',
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(_ChatMessage(text: 'Chat cleared! Ask me anything 😊', isUser: false, time: DateTime.now()));
            }),
          ),
        ],
      ),
      body: Column(children: [
        // Quick prompts
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              '📝 Explain a concept', '🔢 Solve a problem', '📚 Study tips',
              '🧪 Science help', '💻 Code help', '🗓️ Study plan',
            ].map((q) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(q, style: const TextStyle(color: AppColors.darkForeground, fontSize: 12)),
                backgroundColor: AppColors.darkCard,
                side: const BorderSide(color: AppColors.darkBorder),
                onPressed: () { _controller.text = q.substring(2).trim(); },
              ),
            )).toList(),
          ),
        ),
        const Divider(height: 1, color: AppColors.darkBorder),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_thinking ? 1 : 0),
            itemBuilder: (_, i) {
              if (_thinking && i == _messages.length) return const _TypingBubble();
              final msg = _messages[i];
              return _MessageBubble(message: msg);
            },
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          color: AppColors.darkSurface,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 3, minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ask your tutor anything...',
                  hintStyle: const TextStyle(color: AppColors.darkMuted),
                  filled: true, fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.darkBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.darkBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]), shape: BoxShape.circle),
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : AppColors.darkCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser ? null : Border.all(color: AppColors.darkBorder),
              ),
              child: Text(message.text, style: TextStyle(color: message.isUser ? Colors.white : AppColors.darkForeground, fontSize: 14, height: 1.5)),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override void initState() { super.initState(); _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }
  @override void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 32, height: 32,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]), shape: BoxShape.circle),
        child: const Icon(Icons.psychology, color: Colors.white, size: 16)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Container(
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: (i == 0 ? _anim.value : i == 1 ? (_anim.value + 0.3).clamp(0,1) : (_anim.value + 0.6).clamp(0,1))),
              shape: BoxShape.circle,
            ),
          ),
        ))),
      ),
    ]);
  }
}
