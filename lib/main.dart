import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/presentation/splash_screen.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de locale para intl (DateFormat, etc.)
  await initializeDateFormatting('es', null);

  // Cargar variables de entorno
  await dotenv.load(fileName: '.env', mergeWith: Platform.environment);

  // Fail-Fast: Validación de entorno al inicio
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw Exception('🔥 Startup Error: SUPABASE_URL is missing from .env');
  }
  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception(
        '🔥 Startup Error: SUPABASE_ANON_KEY is missing from .env');
  }

  // Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Inicializar notificaciones locales (flutter_local_notifications)
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(
    const ProviderScope(
      child: WorkSenseApp(),
    ),
  );
}

class WorkSenseApp extends ConsumerStatefulWidget {
  const WorkSenseApp({super.key});

  @override
  ConsumerState<WorkSenseApp> createState() => _WorkSenseAppState();
}

class _WorkSenseAppState extends ConsumerState<WorkSenseApp> {
  bool _showSplash = true;
  StreamSubscription<String>? _pushNavSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pushNavSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router     = ref.watch(routerProvider);
    final themeMode  = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;
    final locale     = ref.watch(localeProvider).valueOrNull ?? const Locale('es');

    return MaterialApp.router(
      title: 'WorkSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (_showSplash)
              SplashOverlay(
                onDone: () {
                  if (mounted) setState(() => _showSplash = false);
                },
              ),
          ],
        );
      },
    );
  }
}
