// ignore_for_file: unnecessary_cast

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../core/config/supabase_config.dart';
import '../data/models/models.dart';

class AuthState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  const AuthState({this.profile, this.isLoading = false, this.error});
  bool get isAuthenticated => profile != null;
  UserRole get role => profile?.role ?? UserRole.student;
  AuthState copyWith(
          {UserProfile? profile,
          bool? isLoading,
          String? error,
          bool clearError = false}) =>
      AuthState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _init();
  }

  void _init() {
    SupabaseConfig.auth.onAuthStateChange.listen((data) async {
      if (data.session == null) {
        state = const AuthState();
      } else {
        await _loadProfile(data.session!.user.id);
      }
    });
    final session = SupabaseConfig.auth.currentSession;
    if (session != null) {
      _loadProfile(session.user.id);
    } else {
      state = const AuthState();
    }
  }

  Future<void> _loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('profiles')
            .select(
                'id,email,full_name,avatar_url,department,registration_no,designation,created_at')
            .eq('id', userId)
            .single(),
        SupabaseConfig.client
            .from('user_roles')
            .select('role')
            .eq('user_id', userId)
            .single(),
      ]);
      final role = UserRoleX.from(
          (results[1] as Map<String, dynamic>)['role'] as String? ?? 'student');
      state = AuthState(
          profile:
              UserProfile.fromJson(results[0] as Map<String, dynamic>, role));
    } catch (e) {
      state = AuthState(error: _friendly(e));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final r = await SupabaseConfig.auth.signInWithPassword(
          email: email.trim().toLowerCase(), password: password);
      if (r.user != null) {
        await _loadProfile(r.user!.id);
        _logLoginAsync(r.user!.id);
      }
    } on AuthException catch (e) {
      state = AuthState(error: e.message);
    } catch (e) {
      state = AuthState(error: _friendly(e));
    }
  }

  Future<void> signUp(
      {required String email,
      required String password,
      required String fullName,
      UserRole role = UserRole.student}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Role is never chosen by the client. A lecturer signup only creates a
      // pending request (server trigger); an admin must approve it.
      final r = await SupabaseConfig.auth.signUp(
          email: email.trim().toLowerCase(),
          password: password,
          data: {
            'full_name': fullName,
            if (role == UserRole.lecturer) 'requested_role': 'lecturer',
          });
      if (r.user != null) {
        await SupabaseConfig.client
            .from('profiles')
            .update({'full_name': fullName}).eq('id', r.user!.id);
        await _loadProfile(r.user!.id);
      }
    } on AuthException catch (e) {
      state = AuthState(error: e.message);
    } catch (e) {
      state = AuthState(error: _friendly(e));
    }
  }

  Future<void> forgotPassword(String email) async {
    await SupabaseConfig.auth.resetPasswordForEmail(email.trim().toLowerCase(),
        redirectTo: 'io.supabase.studylock://reset-password');
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
    } finally {
      state = const AuthState();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final id = state.profile?.id;
    if (id == null) return;
    await SupabaseConfig.client.from('profiles').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', id);
    await _loadProfile(id);
  }

  Future<void> _logLoginAsync(String userId) async {
    try {
      final p = state.profile;
      if (p == null) return;
      String device = 'Flutter App';
      try {
        final di = DeviceInfoPlugin();
        if (!kIsWeb && Platform.isAndroid) {
          final a = await di.androidInfo;
          device =
              '${a.manufacturer} ${a.model} (Android ${a.version.release})';
        } else if (!kIsWeb && Platform.isIOS) {
          final i = await di.iosInfo;
          device = '${i.name} (iOS ${i.systemVersion})';
        }
      } catch (_) {}
      await SupabaseConfig.client.from('login_events').insert({
        'user_id': userId,
        'role': p.role.value,
        'email': p.email,
        'name': p.fullName,
        'device_info': device,
      });
    } catch (_) {}
  }

  String _friendly(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('network') || m.contains('socket'))
      return 'No internet connection.';
    if (m.contains('invalid') || m.contains('credentials'))
      return 'Invalid email or password.';
    return 'Something went wrong. Please try again.';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
final currentUserProvider =
    Provider<UserProfile?>((ref) => ref.watch(authProvider).profile);
final currentRoleProvider =
    Provider<UserRole>((ref) => ref.watch(authProvider).role);
