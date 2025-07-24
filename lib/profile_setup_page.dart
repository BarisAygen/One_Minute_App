import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  int questionIndex = 0;
  final nameController = TextEditingController();
  final answers = <String, dynamic>{};

  final questions = [
    {'key': 'name', 'question': 'Adınız nedir?', 'type': 'text'},
    {
      'key': 'sitting',
      'question': 'Günde kaç saat oturarak vakit geçiriyorsunuz?',
      'type': 'choice',
      'options': ['0–2', '3–5', '6–8', '9+'],
    },
    {
      'key': 'stress',
      'question': 'Stres seviyenizi nasıl değerlendirirsiniz?',
      'type': 'choice',
      'options': ['Düşük', 'Orta', 'Yüksek'],
    },
    {
      'key': 'focus',
      'question': 'Odaklanma seviyeniz nasıl?',
      'type': 'choice',
      'options': ['Zayıf', 'Orta', 'İyi'],
    },
    {
      'key': 'activity',
      'question': 'Ne sıklıkla egzersiz yaparsınız?',
      'type': 'choice',
      'options': ['Nadiren', 'Haftada birkaç kez', 'Her gün'],
    },
    // Yeni Türkçe sorular
    {
      'key': 'phone',
      'question': 'Günde kaç saat telefon kullanıyorsunuz?',
      'type': 'choice',
      'options': ['1 saatten az', '1-3 saat', '4-6 saat', '6+ saat'],
    },
    {
      'key': 'sleep',
      'question': 'Geceleri ortalama kaç saat uyuyorsunuz?',
      'type': 'choice',
      'options': ['4-6', '6-8', '8+'],
    },
    {
      'key': 'break',
      'question': 'Gün içinde ne sıklıkla kısa mola verirsiniz?',
      'type': 'choice',
      'options': ['Hiç', 'Nadiren', 'Sık sık'],
    },
    {
      'key': 'toilet',
      'question': 'Tuvalete gıderken telefonunu da yanına alır mısın?',
      'type': 'choice',
      'options': ['Hiç', 'Nadiren', 'Hep alırım'],
    },
    {
      'key': 'dinner',
      'question': 'Yemek yerken bir şey izleme ihtiyacı duyuyor musun?',
      'type': 'choice',
      'options': ['Hiç', 'Nadiren', 'Her zaman'],
    },
  ];

  void handleAnswer(String? answer) async {
    final currentKey = questions[questionIndex]['key'] as String;

    if (questions[questionIndex]['type'] == 'text') {
      if (nameController.text.trim().isEmpty) return;
      answers[currentKey] = nameController.text.trim();
    } else {
      answers[currentKey] = answer;
    }

    if (questionIndex < questions.length - 1) {
      setState(() => questionIndex++);
    } else {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        ...answers,
        'profileCompleted': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasLoggedIn_$uid', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> current = questions[questionIndex];

    return Scaffold(
      body: Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.yellow, Colors.amber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Profil Oluştur",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  current['question'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                if (current['type'] == 'text')
                  buildInputCard(
                    controller: nameController,
                    label: 'Adınızı girin',
                  ),
                if (current['type'] == 'choice')
                  ...List.generate(
                    (current['options'] as List).length,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => handleAnswer(current['options'][i]),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            current['options'][i],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (current['type'] == 'text') const SizedBox(height: 20),
                if (current['type'] == 'text')
                  ElevatedButton(
                    onPressed: () => handleAnswer(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Devam Et"),
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
    required String label,
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
