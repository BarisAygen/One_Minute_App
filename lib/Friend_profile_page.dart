import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendProfilePage extends StatefulWidget {
  final String friendUid;
  const FriendProfilePage({Key? key, required this.friendUid})
    : super(key: key);

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  final _firestore = FirebaseFirestore.instance;
  late final String _currentUid;
  String? _avatarUrl;
  List<String> _badges = [];
  String _name = '';
  String _email = '';
  int _xp = 0;
  int _streak = 0;
  bool _isLoading = true;
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
    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _fetchFriendData();
  }

  Future<void> _fetchFriendData() async {
    final doc =
        await _firestore.collection('users').doc(widget.friendUid).get();
    final data = doc.data()!;
    setState(() {
      _name = data['name'] ?? '';
      _email = data['email'] ?? '';
      _xp = data['xp'] ?? 0;
      _streak = data['streak'] ?? 0;
      _avatarUrl = data['avatarUrl'] as String?; // ← burada ata
      _badges = List<String>.from(data['badges'] ?? []); // ← üye değişkene ata
      _isLoading = false;
    });
  }

  Future<void> _blockUser() async {
    final batch = _firestore.batch();
    // 1) Arkadaşlık varsa sil
    batch.delete(
      _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('friends')
          .doc(widget.friendUid),
    );
    batch.delete(
      _firestore
          .collection('users')
          .doc(widget.friendUid)
          .collection('friends')
          .doc(_currentUid),
    );
    // 2) Blocked koleksiyonuna ekle
    final blockRef = _firestore
        .collection('users')
        .doc(_currentUid)
        .collection('blocked')
        .doc(widget.friendUid);
    batch.set(blockRef, {'blockedAt': FieldValue.serverTimestamp()});
    await batch.commit();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                  'Profil',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Avatar
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.lightBlue,
                            backgroundImage:
                                _avatarUrl != null
                                    ? NetworkImage(
                                      _avatarUrl!,
                                    ) // ← URL varsa göster
                                    : null, // yoksa default icon
                            child:
                                _avatarUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    )
                                    : null,
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
                              Text(
                                'Ad: $_name',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'E-posta: $_email',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'XP: $_xp',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Streak: $_streak gün',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),

                              if (_badges.isNotEmpty) ...[
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
                                      _badges
                                          .map(
                                            (id) => Chip(
                                              label: Text(_badgeLabel(id)),
                                              backgroundColor:
                                                  Colors.yellow.shade100,
                                            ),
                                          )
                                          .toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Remove Friend Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _blockUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Engelle',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
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
}
