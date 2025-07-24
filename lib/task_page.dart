import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  String? taskText;
  bool isLoading = true;
  bool isCompleted = false;

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadOrAssignTask();
  }

  Future<void> _loadOrAssignTask() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final docRef = firestore.collection('daily_tasks').doc(userId);
    final doc = await docRef.get();
    final lastDoc = await docRef.get();

    if (lastDoc.exists && lastDoc['date'] != today) {
      if (lastDoc['completed'] == false) {
        await firestore.collection('users').doc(userId).update({'streak': 0});
        debugPrint('Streak resetlendi çünkü dün tamamlanmamıştı.');
      }
    }
    if (doc.exists && doc['date'] == today) {
      // Eğer bugün zaten atanmış görev varsa
      final taskDoc =
          await firestore.collection('tasks').doc(doc['taskId']).get();
      setState(() {
        taskText = taskDoc['text'];
        isCompleted = doc['completed'];
        isLoading = false;
      });
      return;
    }

    // Son 14 günün görevlerini al
    final history =
        await firestore
            .collection('users')
            .doc(userId)
            .collection('history')
            .orderBy('date', descending: true)
            .limit(14)
            .get();
    final recentIds = history.docs.map((d) => d['taskId'] as String).toSet();

    // Tüm görevleri al ve uygun olanları karıştır
    final allTasks = await firestore.collection('tasks').get();
    var eligible =
        allTasks.docs.where((d) => !recentIds.contains(d.id)).toList();
    if (eligible.isEmpty) eligible = allTasks.docs.toList();
    eligible.shuffle();
    final newTask = eligible.first;

    // Rastgele saat ve dakika ata (09–19 arası)
    final now = DateTime.now();
    final hour = 9 + Random().nextInt(11);
    final minute = Random().nextInt(60);
    final assignedAt = DateTime(now.year, now.month, now.day, hour, minute);

    // Firestore'a kaydet
    await docRef.set({
      'taskId': newTask.id,
      'date': today,
      'completed': false,
      'assignedAt': assignedAt.toIso8601String(),
    });
    await firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(today)
        .set({'taskId': newTask.id, 'date': today});

    setState(() {
      taskText = newTask['text'];
      isCompleted = false;
      isLoading = false;
    });
  }

  Future<void> _markTaskCompleted() async {
    // Görevi tamamlandı olarak işaretle
    await firestore.collection('daily_tasks').doc(userId).update({
      'completed': true,
    });

    // Kullanıcının xp ve streak değerlerini artır
    await firestore.collection('users').doc(userId).update({
      'xp': FieldValue.increment(10),
      'streak': FieldValue.increment(1),
    });
    // 3) Güncel kullanıcı verisini çek
    final userSnap = await firestore.collection('users').doc(userId).get();
    final data = userSnap.data()!;
    final int streak = data['streak'] ?? 0;
    final int xp = data['xp'] ?? 0;
    final List<String> badges = List<String>.from(data['badges'] ?? []);

    // 4) arkadaş sayısını çek (Sosyal Kuş Rozeti için)
    final friendsSnap =
        await firestore
            .collection('users')
            .doc(userId)
            .collection('friends')
            .get();
    final int friendCount = friendsSnap.docs.length;

    // 5) kayıt tarihinden beri geçen günü hesapla (Sadakat Rozeti için)
    final creationTime =
        FirebaseAuth.instance.currentUser!.metadata.creationTime!;
    final int daysSinceSignup = DateTime.now().difference(creationTime).inDays;

    // 6) Hangi rozetleri vermen gerektiğini kontrol et
    final toAward = <String>[];

    // — İlk Görev Rozeti
    // (history koleksiyonundaki doküman sayısını da kullanabilirsin)
    if (!badges.contains('ilk_gorev')) {
      final historyCount = await firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .get()
          .then((snap) => snap.docs.length);
      if (historyCount >= 1) {
        toAward.add('ilk_gorev');
      }
    }

    // — 10 Görev Rozeti
    if (xp >= 100 /*10 görev×10xp*/ && !badges.contains('onluk')) {
      toAward.add('onluk');
    }

    // — 50 Görev Rozeti
    if (xp >= 500 /*50 görev×10xp*/ && !badges.contains('elli')) {
      toAward.add('elli');
    }

    // — Aylık Sadakat Rozeti (30 gün streak)
    if (streak >= 30 && !badges.contains('aylik_sadakat')) {
      toAward.add('aylik_sadakat');
    }

    // — Sosyal Kuş Rozeti (10 arkadaş)
    if (friendCount >= 10 && !badges.contains('sosyal')) {
      toAward.add('sosyal');
    }

    // — Sadakat Rozeti (365 gün kullanım)
    if (daysSinceSignup >= 365 && !badges.contains('sadakat')) {
      toAward.add('sadakat');
    }

    // 7) Yeni rozetleri Firestore'a ekle
    if (toAward.isNotEmpty) {
      await firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion(toAward),
      });
    }

    // 8) UI güncellemesi
    setState(() => isCompleted = true);
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
            title: const Text('Bugünün Görevi'),
            centerTitle: true,
          ),
        ),
      ),
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
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Sarı başlık kartı
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Color(0xFF64B5F6)],
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
                            'Görevin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // 🔁 Beyaz metin
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Görev kartı
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                taskText ?? 'Bugün için görev bulunamadı.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tamamla butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isCompleted ? null : _markTaskCompleted,
                            icon: Icon(
                              isCompleted ? Icons.check_circle : Icons.check,
                              color: Colors.white,
                            ),
                            label: Text(
                              isCompleted ? 'Tamamlandı' : 'Görevi Tamamla',
                              style: const TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isCompleted ? Colors.grey : Colors.lightBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
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
