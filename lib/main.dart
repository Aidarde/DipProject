import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/branch_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<UserProvider, BranchProvider>(
          create: (_) => BranchProvider(),
          update: (_, userProv, branchProv) {
            final branchName = userProv.user?.branchName;
            if (branchName != null) branchProv!..setBranch(branchName);
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),    // ← здесь
      routes: {
        '/login': (_) => const LoginScreen(),
        '/main':  (_) => const MainScreen(),
        '/admin': (_) => const AdminScreen(),
      },
    );
  }
}

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
        if (authSnap.data == null) {
          return const LoginScreen();
        }
        final uid = authSnap.data!.uid;
        return FutureBuilder<void>(
          future: Provider.of<UserProvider>(context, listen: false).loadUser(uid),
          builder: (ctx2, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final role = Provider.of<UserProvider>(context, listen: false).user?.role;
            return role == 'admin'
                ? const AdminScreen()
                : const MainScreen();
          },
        );
      },
    );
  }
}
