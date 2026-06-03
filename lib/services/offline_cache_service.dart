import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/logging_service.dart';

class OfflineCacheService {
  static const _prefix = 'studylock_cache_';
  static const _expiryPrefix = 'studylock_expiry_';
  static const _defaultTtlMinutes = 30;

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  static Future<void> write(String key, dynamic data, {int ttlMinutes = _defaultTtlMinutes}) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final encoded = jsonEncode(data);
      await prefs.setString('$_prefix$key', encoded);
      final expiry = DateTime.now().add(Duration(minutes: ttlMinutes));
      await prefs.setString('$_expiryPrefix$key', expiry.toIso8601String());
      LoggingService.fine('Cache written: $key (TTL: $ttlMinutes min)');
    } catch (e) {
      LoggingService.warning('Cache write failed: $key', e);
    }
  }

  static Future<T?> read<T>(String key) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final expiryStr = prefs.getString('$_expiryPrefix$key');
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          await prefs.remove('$_prefix$key');
          await prefs.remove('$_expiryPrefix$key');
          return null;
        }
      }
      final encoded = prefs.getString('$_prefix$key');
      if (encoded == null) return null;
      return jsonDecode(encoded) as T;
    } catch (e) {
      LoggingService.warning('Cache read failed: $key', e);
      return null;
    }
  }

  static Future<void> invalidate(String key) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
      await prefs.remove('$_expiryPrefix$key');
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix) || k.startsWith(_expiryPrefix));
      for (final k in keys) { await prefs.remove(k); }
    } catch (_) {}
  }
}
