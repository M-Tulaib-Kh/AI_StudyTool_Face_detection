import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/logging_service.dart';
import 'services/offline_cache_service.dart';
import 'features/theme/theme_provider.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggingService.initialize();
  LoggingService.info('StudyLock starting...');

  tz.initializeTimeZones();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Future.wait([
    SupabaseConfig.initialize(),
    OfflineCacheService.initialize(),
  ]);

  await NotificationService.initialize(notificationsPlugin);

  LoggingService.info('All services initialized.');

  runApp(const ProviderScope(child: StudyLockApp()));
}

class StudyLockApp extends ConsumerWidget {
  const StudyLockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);
    return MaterialApp.router(
      title: 'StudyLock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      routerConfig: router,
    );
  }
}
