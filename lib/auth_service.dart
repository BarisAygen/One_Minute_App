import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<User?> signUp(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        // Firestore’a kullanıcı verilerini ekle
        await firestore.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'xp': 0,
          'streak': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'profileCompleted': false,
        });

        // 🔔 E-posta doğrulaması gönder
        await user.sendEmailVerification();

        // İşte e-posta gönderildiğini bildir
        print('Doğrulama maili gönderildi: $email');
      }

      return user;
    } catch (e) {
      print('Signup Error: $e');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> isFirstLoginOnDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    if (user == null) return true;
    return prefs.getBool('hasLoggedIn_${user.uid}') != true;
  }

  Future<void> markUserAsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    if (user != null) {
      await prefs.setBool('hasLoggedIn_${user.uid}', true);
    }
  }

  Future<bool> isProfileSetupComplete() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.exists && doc.data()?['profileComplete'] == true;
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
