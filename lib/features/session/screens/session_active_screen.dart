import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:studylock/data/models/models.dart' show SessionStatus;
import 'package:vibration/vibration.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/notification_service.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/game_provider.dart';
import '../widgets/circular_timer_widget.dart';

class SessionActiveScreen extends ConsumerStatefulWidget {
  const SessionActiveScreen({super.key});
  @override
  ConsumerState<SessionActiveScreen> createState() =>
      _SessionActiveScreenState();
}

class _SessionActiveScreenState extends ConsumerState<SessionActiveScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  Timer? _detectionTimer;
  DateTime? _lastViolationAt;
  FaceStatus _faceStatus = FaceStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _recordViolation('You left the app during session');
    } else if (state == AppLifecycleState.resumed) {
      _cameraController?.resumePreview().ignore();
    } else if (state == AppLifecycleState.inactive) {
      _cameraController?.pausePreview().ignore();
    }
  }

  Future<void> _initCamera() async {
    final session = ref.read(sessionProvider).activeSession;
    if (session == null || !session.cameraEnabled) return;
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(front, ResolutionPreset.low,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await _cameraController!.initialize();
      _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
              enableClassification: true,
              enableTracking: false,
              minFaceSize: 0.15,
              performanceMode: FaceDetectorMode.fast));
      if (mounted) setState(() {});
      _detectionTimer = Timer.periodic(
          const Duration(seconds: AppConstants.detectionIntervalSeconds), (_) {
        if (!_isDetecting) _runFaceDetection();
      });
    } catch (e) {
      debugPrint('Camera init failed: $e');
    }
  }

  Future<void> _runFaceDetection() async {
    if (_isDetecting ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    _isDetecting = true;
    String? tempPath;
    try {
      final img = await _cameraController!.takePicture();
      tempPath = img.path;
      final faces =
          await _faceDetector!.processImage(InputImage.fromFilePath(tempPath));
      if (!mounted) return;
      if (faces.isEmpty) {
        setState(() => _faceStatus = FaceStatus.warning);
        await _recordViolation('Face not detected');
      } else {
        setState(() => _faceStatus = FaceStatus.monitoring);
        final face = faces.first;
        final l = face.leftEyeOpenProbability ?? 1.0;
        final r = face.rightEyeOpenProbability ?? 1.0;
        if (l < AppConstants.eyeOpenThreshold &&
            r < AppConstants.eyeOpenThreshold) {
          await _recordViolation('Eyes closed detected');
        } else if ((face.headEulerAngleY ?? 0).abs() >
            AppConstants.faceYawThreshold) {
          await _recordViolation('Looking away from screen');
        }
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      if (tempPath != null) {
        try {
          await File(tempPath).delete();
        } catch (_) {}
      }
      _isDetecting = false;
    }
  }

  Future<void> _recordViolation(String reason) async {
    final now = DateTime.now();
    if (_lastViolationAt != null &&
        now.difference(_lastViolationAt!).inSeconds <
            AppConstants.violationCooldownSeconds) return;
    _lastViolationAt = now;

    ref.read(sessionProvider.notifier).recordViolation();
    final session = ref.read(sessionProvider).activeSession;
    final count = session?.violations ?? 0;

    HapticFeedback.vibrate();
    // ignore: dead_null_aware_expression
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 250, 100, 250]);
    }
    await NotificationService.showViolationWarning(count);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('⚠️ $reason! Warning $count/${AppConstants.maxViolations}'),
        backgroundColor: count >= AppConstants.maxViolations
            ? AppColors.danger
            : AppColors.warning,
        duration: const Duration(seconds: 3),
      ));
    }
    if (count >= AppConstants.maxViolations) await _endSession('failed');
  }

  Future<void> _endSession(String status) async {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    final session = ref.read(sessionProvider).activeSession;
    if (session == null) return;
    final isComplete = status == 'completed';
    await ref.read(sessionProvider.notifier).endSession(
        isComplete ? SessionStatus.completed : SessionStatus.failed);
    if (isComplete) {
      final pts = (session.elapsedSeconds ~/ 60) * AppConstants.xpPerMinute;
      final g = ref.read(gameProvider.notifier);
      await Future.wait([
        g.addPoints(pts),
        g.checkAndUpdateStreak(DateTime.now()),
        g.updateChallenge('daily_1h', session.elapsedSeconds),
        g.updateChallenge('week_5h', session.elapsedSeconds),
        g.updateChallenge('sessions_5', 1),
        g.unlockBadge('first_session'),
        if (session.violations == 0) g.unlockBadge('no_violations'),
        if (session.elapsedSeconds >= 7200) g.unlockBadge('long_session'),
        if (DateTime.now().hour < 8) g.unlockBadge('early_bird'),
      ]);
      await NotificationService.showSessionComplete(
          (session.elapsedSeconds ~/ 60) * AppConstants.xpPerMinute);
      HapticFeedback.heavyImpact();
    }
    if (mounted) {
      context.go('/session-result'
          '?status=$status'
          '&duration=${session.elapsedSeconds}'
          '&violations=${session.violations}'
          '&points=${isComplete ? (session.elapsedSeconds ~/ 60) * AppConstants.xpPerMinute : 0}');
    }
  }

  void _confirmEnd() => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.darkCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('End Session?',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            content: const Text(
                'Ending early marks this session as failed. No XP will be earned.',
                style: TextStyle(color: AppColors.darkMuted)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Keep Going')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _endSession('failed');
                  },
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('End Session')),
            ],
          ));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _faceDetector?.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(sessionProvider);
    final session = ss.activeSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student/session');
      });
      return const ClayScaffold(
          backgroundColor: Color(0xFF060E1A),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF5B8FF9))));
    }

    if (ss.elapsedSeconds >= session.plannedDurationSeconds &&
        session.plannedDurationSeconds > 0) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _endSession('completed'));
    }

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Color(0xFF060E1A),
              Color(0xFF0D1B2A),
              Color(0xFF0A1628)
            ])),
        child: SafeArea(
            child: Stack(children: [
          // Camera preview
          if (session.cameraEnabled &&
              _cameraController?.value.isInitialized == true)
            Positioned(
                top: 16,
                right: 20,
                child: _CameraBox(
                    controller: _cameraController!, status: _faceStatus)),

          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 24),
                _FocusBadge(violations: session.violations),
                const SizedBox(height: 32),
                CircularTimerWidget(
                    elapsed: ss.elapsedSeconds,
                    total: session.plannedDurationSeconds,
                    size: 260),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Chip(
                      Icons.shield_outlined,
                      '${session.blockedApps.length} blocked',
                      AppColors.accent),
                  const SizedBox(width: 10),
                  _Chip(
                      session.cameraEnabled
                          ? Icons.center_focus_strong
                          : Icons.videocam_off_outlined,
                      session.cameraEnabled ? 'AI On' : 'No Camera',
                      session.cameraEnabled
                          ? AppColors.success
                          : AppColors.darkMuted),
                ]),
                if (_faceStatus == FaceStatus.warning) ...[
                  const SizedBox(height: 14),
                  _WarningBanner()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.3),
                ],
                if (session.violations > 0) ...[
                  const SizedBox(height: 14),
                  _ViolationBar(violations: session.violations),
                ],
                const Spacer(),
                GestureDetector(
                    onTap: _confirmEnd,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 32),
                        decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.4),
                                width: 1.5)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stop_circle_outlined,
                                  color: AppColors.danger, size: 20),
                              SizedBox(width: 8),
                              Text('End Session',
                                  style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ]))),
                const SizedBox(height: 32),
              ])),
        ])),
      ),
    );
  }
}

class _CameraBox extends StatelessWidget {
  final CameraController controller;
  final FaceStatus status;
  const _CameraBox({required this.controller, required this.status});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FaceStatus.warning => AppColors.warning,
      FaceStatus.monitoring => AppColors.success,
      _ => AppColors.darkBorder
    };
    return Container(
        width: 84,
        height: 108,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 1.5)),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          CameraPreview(controller),
          Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle))),
        ]));
  }
}

class _FocusBadge extends StatelessWidget {
  final int violations;
  const _FocusBadge({required this.violations});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  Icon(Icons.radio_button_checked,
                      color: AppColors.success, size: 9),
                  SizedBox(width: 7),
                  Text('FOCUS MODE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                ]))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
                duration: 2800.ms,
                color: AppColors.success.withValues(alpha: 0.3)),
        if (violations > 0) ...[
          const SizedBox(width: 10),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4))),
              child: Text('$violations/${AppConstants.maxViolations}',
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 13))),
        ],
      ]);
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 13))
      ]));
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35))),
      child: const Row(children: [
        Icon(Icons.center_focus_weak, color: AppColors.warning, size: 18),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Face Not Detected',
              style: TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.w600)),
          Text('Stay in camera frame to avoid violation',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
      ]));
}

class _ViolationBar extends StatelessWidget {
  final int violations;
  const _ViolationBar({required this.violations});
  @override
  Widget build(BuildContext context) {
    final pct = violations / AppConstants.maxViolations;
    return Column(children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              color: pct > 0.6 ? AppColors.danger : AppColors.warning,
              minHeight: 5)),
      const SizedBox(height: 5),
      Text(
          '$violations / ${AppConstants.maxViolations} violations before session fails',
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }
}

enum FaceStatus { idle, monitoring, warning }
