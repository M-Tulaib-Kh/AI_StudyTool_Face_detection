import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
        icon: Icons.lock_outline,
        title: 'Focus Lock',
        subtitle:
            'AI-powered proctoring monitors your study sessions using face detection. Stay focused, earn rewards.',
        color: Color(0xFF5B8FF9)),
    _Slide(
        icon: Icons.school_outlined,
        title: 'Academic Hub',
        subtitle:
            'Access lectures, submit assignments, take quizzes. Everything you need in one place.',
        color: Color(0xFF7B6FEF)),
    _Slide(
        icon: Icons.emoji_events_outlined,
        title: 'Earn & Grow',
        subtitle:
            'Earn XP, unlock badges, maintain streaks. Turn studying into an achievement.',
        color: Color(0xFF10B981)),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          Align(
              alignment: Alignment.topRight,
              child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Skip',
                      style: TextStyle(color: AppColors.darkMuted)))),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _slides.length,
              itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _page == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _page == i
                                  ? AppColors.primary
                                  : AppColors.darkBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ))),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_page < _slides.length - 1) {
                        _ctrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(
                        _page == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _Slide(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  // ignore: unused_element_parameter
  const _SlideView({super.key, required this.slide});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: Icon(slide.icon, size: 56, color: slide.color),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 40),
        Text(slide.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center)
            .animate()
            .fadeIn(delay: 200.ms)
            .slideY(begin: 0.3),
        const SizedBox(height: 16),
        Text(slide.subtitle,
                style: const TextStyle(
                    color: AppColors.darkMuted, fontSize: 16, height: 1.6),
                textAlign: TextAlign.center)
            .animate()
            .fadeIn(delay: 350.ms),
      ]),
    );
  }
}
