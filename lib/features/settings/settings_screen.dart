import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/models.dart';
import '../../features/theme/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../shared/widgets/app_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _studyReminders = true;
  bool _assignmentAlerts = true;
  bool _sessionAlerts = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentRoleProvider);
    final isDark = ref.watch(themeModeProvider.notifier).isDark;
    final isUrdu = ref.watch(languageProvider.notifier).isUrdu;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'ترتیبات' : 'Settings',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // Profile section
          _Section(
            title: isUrdu ? 'پروفائل' : 'Profile',
            children: [
              _InfoTile(Icons.person_outline, isUrdu ? 'نام' : 'Name', user?.fullName ?? ''),
              _InfoTile(Icons.email_outlined, isUrdu ? 'ای میل' : 'Email', user?.email ?? ''),
              _InfoTile(Icons.school_outlined, isUrdu ? 'محکمہ' : 'Department', user?.department ?? 'N/A'),
              _InfoTile(Icons.badge_outlined, isUrdu ? 'کردار' : 'Role', role.name.toUpperCase()),
            ],
          ),

          // Appearance
          _Section(
            title: isUrdu ? 'ظاہری شکل' : 'Appearance',
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: isUrdu ? 'ڈارک موڈ' : 'Dark Mode',
                subtitle: isDark ? (isUrdu ? 'فعال' : 'Enabled') : (isUrdu ? 'غیر فعال' : 'Disabled'),
                value: isDark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              ),
            ],
          ),

          // Language
          _Section(
            title: isUrdu ? 'زبان' : 'Language',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: _LangBtn(
                      label: 'English',
                      selected: !isUrdu,
                      onTap: () => ref.read(languageProvider.notifier).setEnglish(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LangBtn(
                      label: 'اردو',
                      selected: isUrdu,
                      onTap: () => ref.read(languageProvider.notifier).setUrdu(),
                    ),
                  ),
                ]),
              ),
            ],
          ),

          // Notifications
          _Section(
            title: isUrdu ? 'اطلاعات' : 'Notifications',
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                title: isUrdu ? 'مطالعہ یاد دہانی' : 'Study Reminders',
                value: _studyReminders,
                onChanged: (v) => setState(() => _studyReminders = v),
              ),
              _SwitchTile(
                icon: Icons.assignment_outlined,
                title: isUrdu ? 'اسائنمنٹ الرٹ' : 'Assignment Alerts',
                value: _assignmentAlerts,
                onChanged: (v) => setState(() => _assignmentAlerts = v),
              ),
              _SwitchTile(
                icon: Icons.timer_outlined,
                title: isUrdu ? 'سیشن الرٹ' : 'Session Alerts',
                value: _sessionAlerts,
                onChanged: (v) => setState(() => _sessionAlerts = v),
              ),
              ListTile(
                leading: const Icon(Icons.notification_add_outlined, color: AppColors.primary),
                title: Text(isUrdu ? 'ٹیسٹ اطلاع' : 'Send Test Notification',
                  style: const TextStyle(color: AppColors.darkForeground)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.darkMuted),
                onTap: () => NotificationService.showNotification(
                  id: 1,
                  title: '🎓 StudyLock',
                  body: isUrdu ? 'اطلاع ٹیسٹ کامیاب!' : 'Test notification working!',
                ),
              ),
            ],
          ),

          // Quick navigation
          _Section(
            title: isUrdu ? 'فوری رسائی' : 'Quick Access',
            children: [
              _NavTile(Icons.leaderboard, isUrdu ? 'لیڈر بورڈ' : 'Leaderboard', () => context.push('/ranking')),
              _NavTile(Icons.calendar_today, isUrdu ? 'ٹائم ٹیبل' : 'Timetable', () => context.push('/timetable')),
              _NavTile(Icons.auto_awesome, isUrdu ? 'اے آئی ٹیوٹر' : 'AI Tutor', () => context.push('/ai-tutor')),
              _NavTile(Icons.people_alt_outlined, isUrdu ? 'والدین پورٹل' : 'Parent Portal', () => context.push('/parent-portal')),
              if (role == UserRole.lecturer)
                _NavTile(Icons.bar_chart, isUrdu ? 'میری کارکردگی' : 'My Performance', () => context.push('/lecturer-performance')),
            ],
          ),

          // Account
          _Section(
            title: isUrdu ? 'اکاؤنٹ' : 'Account',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: AppButton(
                  label: isUrdu ? 'لاگ آؤٹ' : 'Sign Out',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                  },
                  color: AppColors.danger,
                  icon: Icons.logout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('StudyLock v1.0.0 • Powered by Gemini AI',
              style: const TextStyle(color: AppColors.darkMuted, fontSize: 11)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.darkMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoTile(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 20),
    title: Text(label, style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)),
    trailing: Text(value, style: const TextStyle(color: AppColors.darkForeground, fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon; final String title; final String? subtitle;
  final bool value; final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.title, this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: AppColors.primary, size: 20),
    title: Text(title, style: const TextStyle(color: AppColors.darkForeground, fontSize: 14)),
    subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppColors.darkMuted, fontSize: 12)) : null,
    value: value,
    activeThumbColor: AppColors.primary,
    onChanged: onChanged,
  );
}

class _NavTile extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const _NavTile(this.icon, this.title, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 20),
    title: Text(title, style: const TextStyle(color: AppColors.darkForeground, fontSize: 14)),
    trailing: const Icon(Icons.chevron_right, color: AppColors.darkMuted),
    onTap: onTap,
  );
}

class _LangBtn extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _LangBtn({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.darkSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.primary : AppColors.darkBorder),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.darkMuted, fontWeight: FontWeight.w700, fontSize: 14)),
    ),
  );
}
