import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

class LoggingService {
  static final Logger _logger = Logger('StudyLock');

  static void initialize() {
    Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
        if (record.error != null) debugPrint('  Error: ${record.error}');
        if (record.stackTrace != null) debugPrint('  Stack: ${record.stackTrace}');
      }
    });
  }

  static void info(String message, [Object? data]) => _logger.info(message, data);
  static void warning(String message, [Object? error, StackTrace? stack]) => _logger.warning(message, error, stack);
  static void severe(String message, [Object? error, StackTrace? stack]) => _logger.severe(message, error, stack);
  static void fine(String message) => _logger.fine(message);
}
