import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:one_minute_app/friend_profile_page.dart';
import 'package:one_minute_app/invite_requests_page.dart';
import 'package:one_minute_app/AddFriend_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
          child: Column(
            children: [
              // Üst başlık kartı
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          _db
                              .collection('users')
                              .doc(userId)
                              .collection('friends')
                              .snapshots(),
                      builder: (ctx, snap) {
                        final count = snap.hasData ? snap.data!.docs.length : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.yellow, Colors.amber],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Arkadaşlarım ($count)',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.black87),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddFriendPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Arkadaş listesi
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _db
                          .collection('users')
                          .doc(userId)
                          .collection('friends')
                          .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final friends = snap.data!.docs;
                    if (friends.isEmpty) {
                      return Center(
                        child: Text(
                          'Hiç arkadaşın yok.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: friends.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final doc = friends[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return Container(
                          padding: const EdgeInsets.all(12),
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
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage:
                                  data['avatarUrl'] != null
                                      ? NetworkImage(data['avatarUrl'])
                                      : null,
                              child:
                                  data['avatarUrl'] == null
                                      ? const Icon(Icons.person)
                                      : null,
                            ),
                            title: Text(data['name'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeFriend(doc.id),
                            ),
                            onTap: () => _viewFriendProfile(doc.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Davet Kutusu butonu (alt sol)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InviteRequestsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Davet Kutusu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeFriend(String friendUid) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(userId).collection('friends').doc(friendUid),
    );
    batch.delete(
      _db.collection('users').doc(friendUid).collection('friends').doc(userId),
    );
    await batch.commit();
  }

  void _viewFriendProfile(String friendUid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendProfilePage(friendUid: friendUid),
      ),
    );
  }
}
