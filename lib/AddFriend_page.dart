import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<QueryDocumentSnapshot> _results = [];
  bool _isSearching = false;

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _results = [];
    });

    // Search by email (exact match) or name (prefix)
    final byEmail =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: query)
            .get();

    final byName =
        await _firestore
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: query + '\uf8ff')
            .get();

    // Combine, exclude self
    final all =
        [
          ...byEmail.docs,
          ...byName.docs,
        ].where((doc) => doc.id != _currentUid).toSet().toList();

    setState(() {
      _results = all;
      _isSearching = false;
    });
  }

  Future<void> _sendRequest(QueryDocumentSnapshot userDoc) async {
    final targetUid = userDoc.id;
    final targetData = userDoc.data() as Map<String, dynamic>;

    final batch = _firestore.batch();

    // Outgoing for current user
    final outgoingRef = _firestore
        .collection('users')
        .doc(_currentUid)
        .collection('friendRequests')
        .doc('outgoing')
        .collection('items')
        .doc(targetUid);
    batch.set(outgoingRef, {
      'name': targetData['name'],
      'email': targetData['email'],
      'sentAt': FieldValue.serverTimestamp(),
    });

    // Incoming for target user
    final incomingRef = _firestore
        .collection('users')
        .doc(targetUid)
        .collection('friendRequests')
        .doc('incoming')
        .collection('items')
        .doc(_currentUid);
    final me = await _firestore.collection('users').doc(_currentUid).get();
    final meData = me.data()!;
    batch.set(incomingRef, {
      'name': meData['name'],
      'email': meData['email'],
      'sentAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Davet gönderildi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaş Ekle'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'E-posta veya ad ile ara',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _searchUsers(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_isSearching ? 'Aranıyor…' : 'Ara'),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child:
                      _isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, i) {
                              final doc = _results[i];
                              final data = doc.data() as Map<String, dynamic>;
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(data['name'] ?? ''),
                                subtitle: Text(data['email'] ?? ''),
                                trailing: ElevatedButton(
                                  onPressed: () => _sendRequest(doc),
                                  child: const Text('Davet Gönder'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            },
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
