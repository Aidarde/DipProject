// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/firebase_options.dart';
import 'services/fcm_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/branch_provider.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_detail_screen.dart';
import 'theme/theme.dart';

/// Навигатор для переходов из уведомлений
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  final code   = prefs.getString('locale') ?? 'ru';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDark)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(Locale(code))),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<UserProvider, BranchProvider>(
          create: (_) => BranchProvider(),
          update: (_, userProv, branchProv) {
            final branch = userProv.user?.branchName;
            if (branch != null) branchProv!..setBranch(branch);
            return branchProv!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Обработка холодного старта через пуш
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((msg) {
      final orderId = msg?.data['orderId'];
      if (orderId != null) {
        Future.microtask(() {
          navigatorKey.currentState
              ?.pushNamed('/orderDetails', arguments: orderId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProv  = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // темы
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProv.themeMode,
      // локализация
      locale: localeProv.locale,
      supportedLocales: const [Locale('ru'), Locale('ky')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // экран-оболочка авторизации
      home: const AuthWrapper(),
      routes: {
        '/login'       : (_) => const LoginScreen(),
        '/main'        : (_) => const MainScreen(),
        '/admin'       : (_) => const AdminScreen(),
        '/orders'      : (_) => const OrdersScreen(),
        '/orderDetails': (_) => const OrderDetailScreen(),
      },
    );
  }
}

/// Показ Login или Profile в зависимости от authState
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final fbUser = authSnap.data;
        if (fbUser == null) {
          return const LoginScreen();
        }
        // есть токен FirebaseAuth — грузим профиль
        return _UserLoader(uid: fbUser.uid);
      },
    );
  }
}

/// Один раз вызывает loadUser и по завершении переходит к Main/Admin
class _UserLoader extends StatefulWidget {
  final String uid;
  const _UserLoader({required this.uid});

  @override
  State<_UserLoader> createState() => _UserLoaderState();
}

class _UserLoaderState extends State<_UserLoader> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = context.read<UserProvider>().loadUser(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = context.read<UserProvider>().user?.role;
        return role == 'admin'
            ? const AdminScreen()
            : const MainScreen();
      },
    );
  }
}
