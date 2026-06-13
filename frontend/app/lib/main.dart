import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show PointerDeviceKind;

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'providers/occupation_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OccupationProvider()),
      ],
      child: const CoopProperaApp(),
    ),
  );
}

class CoopProperaApp extends StatefulWidget {
  const CoopProperaApp({super.key});

  @override
  State<CoopProperaApp> createState() => _CoopProperaAppState();
}

class _CoopProperaAppState extends State<CoopProperaApp> {
  Timer? _inactivityTimer;
  // 120 minutos = 7200 segundos
  static const int _timeoutMinutes = 120;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      const Duration(minutes: _timeoutMinutes),
      _handleInactivity,
    );
  }

  void _handleInactivity() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      authProvider.logout();
    }
  }

  void _resetInactivityTimer(PointerEvent details) {
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Listener(
      onPointerDown: _resetInactivityTimer,
      onPointerMove: _resetInactivityTimer,
      onPointerUp: _resetInactivityTimer,
      child: FluentApp(
        title: 'Coop Propera',
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        scrollBehavior: const FluentScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
