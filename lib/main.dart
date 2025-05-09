import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'root_page.dart';
import 'auth_page.dart';
import 'verify_email_page.dart';
import 'profile_setup_page.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OneMinuteApp());
}

class OneMinuteApp extends StatelessWidget {
  const OneMinuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1 Dakika',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const RootPage(),
        '/auth/login': (_) => const AuthPage(initialIsLogin: true),
        '/auth/signup': (_) => const AuthPage(initialIsLogin: false),
        '/verify': (_) => const VerifyEmailPage(),
        '/profile': (_) => const ProfileSetupPage(),
        '/home': (_) => const Home(),
      },
      theme: ThemeData(
        primaryColor: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.yellow),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.lightBlue,
        ),
      ),
    );
  }
}
