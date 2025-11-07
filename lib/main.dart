import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'helpers/notification_helper.dart';
import 'helpers/user_session.dart';
import 'helpers/security_helper.dart';
import 'screens/lock_screen_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('id_ID', null);

  await NotificationHelper.instance.init();
  await UserSession.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastPausedTime;
  final int _lockTimeoutSeconds = 10; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
      print("[LIFECYCLE] Aplikasi Paused pada $_lastPausedTime");

    } else if (state == AppLifecycleState.resumed) {
      print("[LIFECYCLE] Aplikasi Resumed");
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    if (!UserSession.instance.isLoggedIn) return;

    final isLockEnabled = await SecurityHelper.instance.isLockEnabled();
    if (!isLockEnabled) return;

    if (_lastPausedTime != null) {
      final timeInBackground = DateTime.now().difference(_lastPausedTime!);
      print("[LIFECYCLE] Durasi di background: ${timeInBackground.inSeconds} detik");

      if (timeInBackground.inSeconds >= _lockTimeoutSeconds) {
        print("[LIFECYCLE] 🔒 Timeout tercapai. Mengunci aplikasi...");
        
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const LockScreenPage(purpose: LockScreenPurpose.unlockApp),
          ),
        );
      }
    }
    _lastPausedTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'JejakPena',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B4A),
          primary: const Color(0xFFFF6B4A),
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A))));
          }
          return snapshot.data!;
        },
      ),
    );
  }

  Future<Widget> _getInitialScreen() async {
    if (UserSession.instance.isLoggedIn) {
      final isLockEnabled = await SecurityHelper.instance.isLockEnabled();
      if (isLockEnabled) {
        return const LockScreenPage(purpose: LockScreenPurpose.unlockApp);
      } else {
        return const HomePage();
      }
    } else {
      return const LoginPage();
    }
  }
}