import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/supabase_config.dart';
// ignore: unused_import
import '../../../data/models/models.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/empty_state.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('*, user_roles(role), role_requests(requested_role, status)')
          .order('created_at', ascending: false);
      if (mounted)
        setState(() {
          _users = (data as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      await SupabaseConfig.client
          .from('user_roles')
          .update({'role': newRole}).eq('user_id', userId);
      await _loadUsers();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Role updated to $newRole'),
            backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.danger));
    }
  }

  bool _hasPendingRequest(Map<String, dynamic> user) {
    final r = user['role_requests'];
    final list = r is List ? r : (r is Map ? [r] : const []);
    return list.any((e) => e is Map && e['status'] == 'pending');
  }

  String _getRole(Map<String, dynamic> user) {
    final roles = user['user_roles'];
    if (roles is List && roles.isNotEmpty)
      return roles.first['role'] as String? ?? 'student';
    if (roles is Map) return roles['role'] as String? ?? 'student';
    return 'student';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      final role = _getRole(u);
      final name = (u['full_name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      if (_filter != 'all' && role != _filter) return false;
      if (_search.isNotEmpty &&
          !name.contains(_search) &&
          !email.contains(_search)) return false;
      return true;
    }).toList();

    return ClayScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Users',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadUsers)
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon:
                    Icon(Icons.search, color: AppColors.darkMuted, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 10)),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
              children: ['all', 'student', 'lecturer', 'admin'].map((r) {
            final sel = _filter == r;
            return GestureDetector(
              onTap: () => setState(() => _filter = r),
              child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                      color: sel ? AppColors.primary : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color:
                              sel ? AppColors.primary : AppColors.darkBorder)),
                  child: Text(r[0].toUpperCase() + r.substring(1),
                      style: TextStyle(
                          color: sel ? Colors.white : AppColors.darkMuted,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 13))),
            );
          }).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Padding(padding: EdgeInsets.all(16), child: ShimmerList())
              : filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outlined,
                      title: 'No Users Found',
                      subtitle: 'Try changing the filter or search')
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          final role = _getRole(u);
                          final name = u['full_name'] as String? ?? 'Unknown';
                          final email = u['email'] as String? ?? '';
                          final avatar = u['avatar_url'] as String?;
                          final roleColor = role == 'admin'
                              ? AppColors.danger
                              : role == 'lecturer'
                                  ? AppColors.accent
                                  : AppColors.success;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(boxShadow: AppShadows.clay, 
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(22),
                                border:
                                    Border.all(color: AppColors.darkBorder)),
                            child: Row(children: [
                              CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  backgroundImage: avatar != null
                                      ? NetworkImage(avatar)
                                      : null,
                                  child: avatar == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700))
                                      : null),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    Text(email,
                                        style: const TextStyle(
                                            color: AppColors.darkMuted,
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    if (_hasPendingRequest(u))
                                      const Text('Lecturer request pending',
                                          style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                  ])),
                              PopupMenuButton<String>(
                                color: AppColors.darkCard,
                                icon: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color:
                                            roleColor.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              role[0].toUpperCase() +
                                                  role.substring(1),
                                              style: TextStyle(
                                                  color: roleColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_drop_down,
                                              color: roleColor, size: 16),
                                        ])),
                                onSelected: (newRole) =>
                                    _changeRole(u['id'] as String, newRole),
                                itemBuilder: (_) => [
                                  'student',
                                  'lecturer',
                                  'admin'
                                ]
                                    .map((r) => PopupMenuItem(
                                        value: r,
                                        child: Text(
                                            r[0].toUpperCase() + r.substring(1),
                                            style: const TextStyle(
                                                color: Colors.white))))
                                    .toList(),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
