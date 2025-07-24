import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isSending = false;
  bool _isChecking = false;
  bool _isEditingEmail = false;
  final _editEmailCtrl = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;

  @override
  void dispose() {
    _editEmailCtrl.dispose();
    super.dispose();
  }

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
    setState(() => _isEditingEmail = true);
  }

  Future<void> _submitNewEmail() async {
    final newEmail = _editEmailCtrl.text.trim();
    if (newEmail.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await user.updateEmail(newEmail);
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama maili yenilendi.')),
      );
      setState(() => _isEditingEmail = false);
      _editEmailCtrl.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Bir hata oluştu')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
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
                      // Header Card
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

                      // Content based on mode
                      if (_isEditingEmail) ...[
                        TextField(
                          controller: _editEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Yeni e-posta',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _submitNewEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child:
                                _isSending
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Doğrulama Maili Gönder',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => setState(() => _isEditingEmail = false),
                          child: const Text('İptal'),
                        ),
                      ] else ...[
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
                        TextButton(
                          onPressed: _isSending ? null : _sendAgain,
                          child:
                              _isSending
                                  ? const CircularProgressIndicator()
                                  : const Text('Maili Tekrar Gönder'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _editEmail,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          label: const Text(
                            'E-postayı Düzenle',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/auth/signup');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
