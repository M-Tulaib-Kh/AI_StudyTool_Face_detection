import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});
  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  int _durationMinutes = 30;
  bool _cameraEnabled = false;
  final Set<String> _blockedApps = {'Instagram', 'TikTok', 'YouTube', 'Discord'};
  bool _loading = false;

  static const _durations = [15, 25, 30, 45, 60, 90, 120];

  Future<void> _startSession() async {
    if (_cameraEnabled) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required for AI monitoring'), backgroundColor: AppColors.warning));
        setState(() => _cameraEnabled = false);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).startSession(
        plannedDurationSeconds: _durationMinutes * 60,
        blockedApps: _blockedApps.toList(),
        cameraEnabled: _cameraEnabled,
      );
      if (mounted) context.go('/session-active');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground, elevation: 0,
        title: const Text('Setup Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Duration picker
          const Text('Study Duration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10,
            children: _durations.map((d) {
              final sel = _durationMinutes == d;
              return GestureDetector(
                onTap: () => setState(() => _durationMinutes = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.darkBorder),
                  ),
                  child: Text('${d}m', style: TextStyle(
                    color: sel ? Colors.white : AppColors.darkMuted,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // AI Monitoring
          const Text('AI Monitoring', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Uses face detection to ensure you stay focused', style: TextStyle(color: AppColors.darkMuted, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cameraEnabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.darkBorder)),
            child: Row(children: [
              Icon(_cameraEnabled ? Icons.center_focus_strong : Icons.videocam_off_outlined,
                color: _cameraEnabled ? AppColors.primary : AppColors.darkMuted, size: 24),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_cameraEnabled ? 'Camera Monitoring ON' : 'Camera Monitoring OFF',
                  style: TextStyle(color: _cameraEnabled ? AppColors.primary : Colors.white, fontWeight: FontWeight.w600)),
                const Text('Face + eye + head-pose detection', style: TextStyle(color: AppColors.darkMuted, fontSize: 12)),
              ])),
              Switch(value: _cameraEnabled, onChanged: (v) => setState(() => _cameraEnabled = v),
                activeThumbColor: AppColors.primary),
            ]),
          ),
          const SizedBox(height: 28),

          // Blocked apps
          const Text('App Blocking', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Distraction reminders during session', style: TextStyle(color: AppColors.darkMuted, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8,
            children: AppConstants.blockedApps.map((app) {
              final sel = _blockedApps.contains(app);
              return GestureDetector(
                onTap: () => setState(() => sel ? _blockedApps.remove(app) : _blockedApps.add(app)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.danger.withValues(alpha: 0.15) : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.danger.withValues(alpha: 0.4) : AppColors.darkBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (sel) const Icon(Icons.block, color: AppColors.danger, size: 13),
                    if (sel) const SizedBox(width: 4),
                    Text(app, style: TextStyle(color: sel ? AppColors.danger : AppColors.darkMuted, fontSize: 12,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: Column(children: [
              _SummaryRow(label: 'Duration', value: '$_durationMinutes minutes'),
              _SummaryRow(label: 'AI Monitoring', value: _cameraEnabled ? 'Enabled' : 'Disabled'),
              _SummaryRow(label: 'Blocked Apps', value: '${_blockedApps.length} apps'),
              _SummaryRow(label: 'XP Reward', value: '~${_durationMinutes * 2} XP', highlight: true),
            ]),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Start Session', loading: _loading, icon: Icons.play_arrow_rounded, onTap: _startSession),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _SummaryRow({required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 13)),
      const Spacer(),
      Text(value, style: TextStyle(color: highlight ? AppColors.primary : Colors.white,
        fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}
