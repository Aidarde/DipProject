import 'package:enjoy/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';
import 'providers/branch_provider.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    print('🟡 Пользователь: $user');

    if (user == null) {
      print('Нет пользователя → LoginScreen');
      return const LoginScreen();
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print('🟡 Документ не существует. Создаем нового пользователя...');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'role': 'user',
          'email': user.email ?? '',
        });

        return const MainScreen();
      }

      final role = doc.data()?['role'] ?? 'user';
      print('🟢 Роль пользователя: $role');

      if (role == 'admin') {
        return const AdminScreen();
      } else {
        return const MainScreen();
      }
    } catch (e) {
      print('Ошибка при определении роли: $e');
      return const Scaffold(
        body: Center(child: Text('Произошла ошибка при запуске приложения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Enjoy App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.red),
        routes: {
          '/admin': (context) => const AdminScreen(),
          '/main': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
        },
        home: FutureBuilder<Widget>(
          future: _getInitialScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              print('Snapshot error: ${snapshot.error}');
              return const Scaffold(
                body: Center(child: Text('Ошибка загрузки')),
              );
            } else {
              return snapshot.data!;
            }
          },
        ),
      ),
    );
  }
}
