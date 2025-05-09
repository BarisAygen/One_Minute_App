import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteRequestsPage extends StatelessWidget {
  const InviteRequestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.yellow, Colors.amber],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Davet Kutusu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Gelen davetler listesi
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      db
                          .collection('users')
                          .doc(userId)
                          .collection('friendRequests')
                          .doc('incoming')
                          .collection('items')
                          .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final invites = snap.data!.docs;
                    if (invites.isEmpty) {
                      return Center(
                        child: Text(
                          'Hiç davetin yok.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: invites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final doc = invites[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final senderUid = doc.id;
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['name'] ?? ''),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed:
                                        () => _acceptInvite(userId, senderUid),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _rejectInvite(userId, senderUid),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvite(String userId, String senderUid) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    // Me → arkadaş olarak ekle
    final myFriendRef = db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(senderUid);
    // Karşı taraf → seni ekle
    final theirFriendRef = db
        .collection('users')
        .doc(senderUid)
        .collection('friends')
        .doc(userId);

    // Kullanıcı verilerini al
    final senderSnap = await db.collection('users').doc(senderUid).get();
    final meSnap = await db.collection('users').doc(userId).get();
    final senderData = senderSnap.data()!;
    final myData = meSnap.data()!;

    batch.set(myFriendRef, {
      'name': senderData['name'],
      'avatarUrl': senderData['avatarUrl'] ?? '',
    });
    batch.set(theirFriendRef, {
      'name': myData['name'],
      'avatarUrl': myData['avatarUrl'] ?? '',
    });

    // Daveti sil (incoming + outgoing)
    final incRef = db
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .doc('incoming')
        .collection('items')
        .doc(senderUid);
    final outRef = db
        .collection('users')
        .doc(senderUid)
        .collection('friendRequests')
        .doc('outgoing')
        .collection('items')
        .doc(userId);

    batch.delete(incRef);
    batch.delete(outRef);

    await batch.commit();
  }

  Future<void> _rejectInvite(String userId, String senderUid) async {
    final db = FirebaseFirestore.instance;
    // Gelen daveti sil
    await db
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .doc('incoming')
        .collection('items')
        .doc(senderUid)
        .delete();
  }
}
