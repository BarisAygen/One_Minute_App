import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_minute_app/friends_page.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _avatarUrl;
  final _picker = ImagePicker();
  String name = '';
  int xp = 0;
  int level = 1;
  int streak = 0;
  List<String> badges = [];
  bool isLoading = true;

  String _badgeLabel(String id) {
    switch (id) {
      case 'istikrar':
        return 'İstikrar Rozeti 🏆 (7 Gün)';
      case 'azimli':
        return 'Azimli Rozeti 🥇 (20 Görev)';
      case 'ilk_gorev':
        return 'İlk Adım Rozeti 🎉';
      case 'onluk':
        return 'On’uncu Görev Rozeti 🔟';
      case 'elli':
        return 'Elli Görev Rozeti 🏅';
      case 'aylik_sadakat':
        return 'Aylık Sadakat Rozeti 📅 (30 Gün)';
      case 'sosyal':
        return 'Sosyal Kuş Rozeti 🕊️ (10 Arkadaş)';
      case 'sadakat':
        return 'Sadakat Rozeti 🥇 (1 Yıl)';
      default:
        return 'Bilinmeyen Rozet';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    setState(() {
      _avatarUrl = data['avatarUrl'];
      name = data['name'] ?? 'Kullanıcı';
      xp = data['xp'] ?? 0;
      level = (xp ~/ 50) + 1;
      streak = data['streak'] ?? 0;
      badges = List<String>.from(data['badges'] ?? []);
      isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage(initialIsLogin: true)),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final pic = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pic == null) return;
    final file = File(pic.path);
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('$userId.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await firestore.collection('users').doc(userId).update({'avatarUrl': url});
    setState(() => _avatarUrl = url);
  }

  Future<void> _deleteAccount() async {
    final should = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hesabı Sil'),
            content: const Text('Emin misin? Bu tüm datanı silecek'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (should == true) {
      await firestore.collection('users').doc(userId).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage(initialIsLogin: true)),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow, Colors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profilim'),
            actions: [
              IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
            ],
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6E3), Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.lightBlue,
                          backgroundImage:
                              _avatarUrl != null
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                          child:
                              _avatarUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.person, 'Ad', name),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.local_fire_department,
                            'XP',
                            xp.toString(),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.star, 'Seviye', level.toString()),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Streak',
                            '$streak gün',
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (xp % 50) / 50,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.lightBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bir sonraki seviyeye ${50 - (xp % 50)} XP kaldı',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Badges
                    if (badges.isNotEmpty) ...[
                      const Text(
                        '🎖 Rozetler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            badges.map((b) {
                              return Chip(
                                label: Text(_badgeLabel(b)),
                                backgroundColor: Colors.yellow.shade100,
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Spacer(), // alt kısım tam ekrana oturur
                    // Arkadaşlarım
                    ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FriendsPage(),
                            ),
                          ),
                      icon: const Icon(Icons.group),
                      label: StreamBuilder<QuerySnapshot>(
                        stream:
                            firestore
                                .collection('users')
                                .doc(userId)
                                .collection('friends')
                                .snapshots(),
                        builder: (ctx, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          return Text('Arkadaşlarım ($count)');
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Hesabı Sil
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Hesabı Sil'),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightBlue),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Expanded(child: Text(value)),
      ],
    );
  }
}
