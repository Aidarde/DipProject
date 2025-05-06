import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/login_screen.dart';
import 'theme/theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'services/fcm_service.dart';
import 'config/firebase_options.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv  = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProv.themeMode,

      locale: localeProv.locale,
      supportedLocales: const [Locale('ru'), Locale('ky')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const AuthWrapper(),        // в MainScreen
      routes: {
        '/login': (_) => const LoginScreen(),
        '/main' : (_) => const MainScreen(),
        '/admin': (_) => const AdminScreen(),
      },
    );
  }
}
