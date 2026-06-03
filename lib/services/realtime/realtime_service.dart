// ============================================================
// StudyLock — Supabase Realtime Service
// Fixed: auto-reconnect on network restore
// ============================================================
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../services/logging_service.dart';

typedef RealtimeCallback = void Function(Map<String, dynamic> payload);

class _ChannelConfig {
  final String table;
  final String? filter;
  final RealtimeCallback? onInsert;
  final RealtimeCallback? onUpdate;
  final RealtimeCallback? onDelete;
  _ChannelConfig({required this.table, this.filter, this.onInsert, this.onUpdate, this.onDelete});
}

class RealtimeService {
  static RealtimeService? _instance;
  static RealtimeService get instance => _instance ??= RealtimeService._();
  RealtimeService._() { _watchConnectivity(); }

  final _channels = <String, RealtimeChannel>{};
  final _configs = <String, _ChannelConfig>{};
  StreamSubscription? _connectivitySub;

  void _watchConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && _configs.isNotEmpty) {
        LoggingService.info('Network restored — reconnecting ${_configs.length} realtime channels');
        _reconnectAll();
      }
    });
  }

  void _reconnectAll() {
    for (final entry in _configs.entries) {
      _subscribe(entry.key, entry.value);
    }
  }

  RealtimeChannel subscribeTable({
    required String channelName,
    required String table,
    String? filter,
    RealtimeCallback? onInsert,
    RealtimeCallback? onUpdate,
    RealtimeCallback? onDelete,
  }) {
    final config = _ChannelConfig(
      table: table, filter: filter,
      onInsert: onInsert, onUpdate: onUpdate, onDelete: onDelete,
    );
    _configs[channelName] = config;
    return _subscribe(channelName, config);
  }

  RealtimeChannel _subscribe(String channelName, _ChannelConfig config) {
    // Remove existing channel first
    final existing = _channels.remove(channelName);
    if (existing != null) {
      try { SupabaseConfig.client.removeChannel(existing); } catch (_) {}
    }

    final channel = SupabaseConfig.client.channel(channelName);

    PostgresChangeFilter? pgFilter;
    if (config.filter != null) {
      final parts = config.filter!.split('=');
      if (parts.length == 2) {
        pgFilter = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: parts[0],
          value: parts[1],
        );
      }
    }

    if (config.onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: config.table,
        filter: pgFilter,
        callback: (payload) => config.onInsert!(payload.newRecord),
      );
    }
    if (config.onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: config.table,
        callback: (payload) => config.onUpdate!(payload.newRecord),
      );
    }
    if (config.onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: config.table,
        callback: (payload) => config.onDelete!(payload.oldRecord),
      );
    }

    channel.subscribe((status, [error]) {
      if (error != null) {
        LoggingService.warning('Realtime error on $channelName', error);
      } else {
        LoggingService.fine('Realtime $channelName: $status');
      }
    });

    _channels[channelName] = channel;
    return channel;
  }

  void unsubscribe(String channelName) {
    _configs.remove(channelName);
    final ch = _channels.remove(channelName);
    if (ch != null) {
      try { SupabaseConfig.client.removeChannel(ch); } catch (_) {}
    }
  }

  void unsubscribeAll() {
    for (final ch in _channels.values) {
      try { SupabaseConfig.client.removeChannel(ch); } catch (_) {}
    }
    _channels.clear();
    _configs.clear();
  }

  void dispose() {
    _connectivitySub?.cancel();
    unsubscribeAll();
  }
}

// ── Realtime Attendance Provider ─────────────────────────────
final realtimeAttendanceProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  RealtimeService.instance.subscribeTable(
    channelName: 'realtime_attendance',
    table: 'attendance',
    onInsert: (p) => controller.add({'type': 'insert', 'data': p}),
    onUpdate: (p) => controller.add({'type': 'update', 'data': p}),
    onDelete: (p) => controller.add({'type': 'delete', 'data': p}),
  );
  ref.onDispose(() {
    controller.close();
    RealtimeService.instance.unsubscribe('realtime_attendance');
  });
  return controller.stream;
});

// ── Realtime Session Provider ─────────────────────────────────
final realtimeSessionProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  RealtimeService.instance.subscribeTable(
    channelName: 'realtime_sessions',
    table: 'study_sessions',
    onInsert: (p) => controller.add({'type': 'insert', 'data': p}),
    onUpdate: (p) => controller.add({'type': 'update', 'data': p}),
  );
  ref.onDispose(() {
    controller.close();
    RealtimeService.instance.unsubscribe('realtime_sessions');
  });
  return controller.stream;
});

// ── Realtime Notifications Provider ──────────────────────────
final realtimeNotificationsProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final uid = SupabaseConfig.auth.currentUser?.id;
  if (uid == null) return const Stream.empty();
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  RealtimeService.instance.subscribeTable(
    channelName: 'realtime_notifications_$uid',
    table: 'notifications',
    onInsert: (p) => controller.add({'type': 'insert', 'data': p}),
  );
  ref.onDispose(() {
    controller.close();
    RealtimeService.instance.unsubscribe('realtime_notifications_$uid');
  });
  return controller.stream;
});
