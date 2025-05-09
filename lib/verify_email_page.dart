import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isSending = false;
  bool _isChecking = false;
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _sendAgain() async {
    setState(() => _isSending = true);
    await user.sendEmailVerification();
    setState(() => _isSending = false);
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    await user.reload();
    if (FirebaseAuth.instance.currentUser!.emailVerified) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Henüz doğrulanmadı.')));
    }
    setState(() => _isChecking = false);
  }

  void _editEmail() {
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6E3), Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Yellow Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
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
                    child: const Text(
                      'E-posta Doğrula',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Instruction Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Lütfen e-postanıza gelen doğrulama bağlantısını tıklayın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Check Verification Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child:
                          _isChecking
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Doğrulamayı Kontrol Et',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend Email Button
                  TextButton(
                    onPressed: _isSending ? null : _sendAgain,
                    child:
                        _isSending
                            ? const CircularProgressIndicator()
                            : const Text('Maili Tekrar Gönder'),
                  ),

                  const SizedBox(height: 8),

                  // Edit Email Link
                  TextButton.icon(
                    onPressed: _editEmail,
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    label: const Text(
                      'E-postayı Düzenle',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
