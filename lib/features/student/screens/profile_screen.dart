import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: unused_import
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../services/storage_service.dart';
import '../../../shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  void _startEdit(dynamic user) {
    _nameCtrl.text = user.fullName;
    _deptCtrl.text = user.department ?? '';
    setState(() => _editing = true);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
      });
      if (mounted)
        setState(() {
          _editing = false;
          _saving = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final file = await StorageService.pickImage();
    if (file == null) return;
    try {
      final result = await StorageService.uploadFile(
          file: file, bucket: StorageBucket.avatars, userId: user.id);
      await ref
          .read(authProvider.notifier)
          .updateProfile({'avatar_url': result.fileUrl});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Avatar updated!'),
            backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final game = ref.watch(gameProvider);
    final session = ref.watch(sessionProvider);
    if (user == null) return const Scaffold(backgroundColor: Color(0xFF060E1A));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          if (!_editing)
            IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _startEdit(user))
          else
            IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _editing = false)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar
          Stack(children: [
            GestureDetector(
                onTap: _uploadAvatar,
                child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.darkCard,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700))
                        : null)),
            Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.darkBackground, width: 2)),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14))),
          ]),
          const SizedBox(height: 8),
          const Text('Tap to change photo',
              style: TextStyle(color: AppColors.darkMuted, fontSize: 12)),
          const SizedBox(height: 20),

          if (_editing) ...[
            _label('Full Name'),
            TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Your name')),
            const SizedBox(height: 12),
            _label('Department'),
            TextField(
                controller: _deptCtrl,
                style: const TextStyle(color: Colors.white),
                decoration:
                    const InputDecoration(hintText: 'e.g. Computer Science')),
            const SizedBox(height: 20),
            AppButton(
                label: 'Save Changes', loading: _saving, onTap: _saveProfile),
            const SizedBox(height: 20),
          ] else ...[
            Text(user.fullName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(user.email,
                style:
                    const TextStyle(color: AppColors.darkMuted, fontSize: 14)),
            const SizedBox(height: 4),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    user.role.name[0].toUpperCase() +
                        user.role.name.substring(1),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
          ],

          const SizedBox(height: 24),
          if (game != null) ...[
            Row(children: [
              _StatCard(
                  label: 'Level',
                  value: '${game.level}',
                  icon: Icons.military_tech,
                  color: AppColors.primary),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'XP',
                  value: '${game.points}',
                  icon: Icons.star,
                  color: AppColors.warning),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Streak',
                  value: '${game.streak}d',
                  icon: Icons.local_fire_department,
                  color: AppColors.accent),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard(
                  label: 'Total Study',
                  value: '${session.totalStudySeconds ~/ 3600}h',
                  icon: Icons.timer,
                  color: AppColors.success),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Badges',
                  value: '${game.badges.where((b) => b.unlocked).length}',
                  icon: Icons.emoji_events,
                  color: const Color(0xFFFFD700)),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Best Streak',
                  value: '${game.longestStreak}d',
                  icon: Icons.trending_up,
                  color: AppColors.danger),
            ]),
          ],

          const SizedBox(height: 24),
          _SettingsTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings')),
          const SizedBox(height: 8),
          _SettingsTile(
              icon: Icons.logout,
              label: 'Sign Out',
              color: AppColors.danger,
              onTap: () => _confirmSignOut()),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.darkCard,
              title: const Text('Sign Out?',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              content: const Text('You will be signed out of StudyLock.',
                  style: TextStyle(color: AppColors.darkMuted)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(authProvider.notifier).signOut();
                    },
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Sign Out')),
              ],
            ));
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600))));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder)),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.darkMuted, fontSize: 10),
                textAlign: TextAlign.center),
          ])));
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _SettingsTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color = Colors.white});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder)),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.darkMuted, size: 18),
          ])));
}
