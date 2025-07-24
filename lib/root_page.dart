import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:one_minute_app/auth_service.dart';
import 'auth_page.dart';
import 'verify_email_page.dart';
import 'profile_setup_page.dart';
import 'home.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _determineStartPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return snapshot.data as Widget;
        } else {
          return const Scaffold(body: Center(child: Text('Error loading app')));
        }
      },
    );
  }

  Future<Widget> _determineStartPage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const AuthPage(); // signup ekranı
    }

    if (!user.emailVerified) {
      return const VerifyEmailPage(); // doğrulama ekranı
    }

    final isFirstLogin = await AuthService().isFirstLoginOnDevice();

    if (isFirstLogin) {
      final setupComplete = await AuthService().isProfileSetupComplete();
      if (!setupComplete) {
        return const ProfileSetupPage();
      }
      await AuthService().markUserAsLoggedIn();
    }

    return const Home(); // uygulama sayfası
  }
}
