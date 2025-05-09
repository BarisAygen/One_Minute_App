import 'package:flutter/material.dart';
import 'auth_service.dart';

/// if true → show **Login** first; if false → show **Sign Up** first
class AuthPage extends StatefulWidget {
  final bool initialIsLogin;
  const AuthPage({Key? key, this.initialIsLogin = true}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool isLogin;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;
  }

  void toggleForm() => setState(() => isLogin = !isLogin);

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    final user =
        isLogin
            ? await authService.signIn(email, password)
            : await authService.signUp(email, password, name);

    if (user != null && context.mounted) {
      if (!isLogin) {
        // after sign-up, go to verify-email screen
        Navigator.pushReplacementNamed(context, '/verify');
        return;
      }
      // for sign-in, check profile flag & go on
      final userDoc =
          await authService.firestore.collection('users').doc(user.uid).get();
      final hasProfile = userDoc.data()?['profileCompleted'] == true;
      Navigator.pushReplacementNamed(
        context,
        hasProfile ? '/home' : '/profile',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogin ? 'Giriş başarısız oldu' : 'Kayıt başarısız oldu',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6E3), Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ▶️ Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.yellow, Colors.amber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ▶️ Name (sign-up only)
                if (!isLogin)
                  buildInputCard(
                    controller: nameController,
                    icon: Icons.person,
                    label: 'Adınız',
                  ),
                if (!isLogin) const SizedBox(height: 16),

                // ▶️ Email
                buildInputCard(
                  controller: emailController,
                  icon: Icons.email,
                  label: 'E-posta',
                ),
                const SizedBox(height: 16),

                // ▶️ Password
                buildInputCard(
                  controller: passwordController,
                  icon: Icons.lock,
                  label: 'Şifre',
                  obscure: true,
                ),
                const SizedBox(height: 28),

                // ▶️ Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ▶️ Toggle
                TextButton(
                  onPressed: toggleForm,
                  child: Text(
                    isLogin
                        ? 'Hesabın yok mu? Kayıt Ol'
                        : 'Zaten hesabın var mı? Giriş Yap',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputCard({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
