import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../help.dart';
import '../levels/readcomp_levels.dart';
import '../levels/sentcomp_levels.dart';
import '../levels/vocabskills_levels.dart';
import '../levels/wordpro_levels.dart';

class HomeMenu extends StatefulWidget {
  final List<String> uniqueIds; // Define uniqueIds here

  const HomeMenu(
      {super.key, required this.uniqueIds}); // Pass it in the constructor

  @override
  _HomeMenuState createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  String nickname = '';
  int xp = 0;
  List<String> completedModules = [];
  List<Map<String, dynamic>> allModules = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllModules();
  }

  Stream<DocumentSnapshot> _fetchUserStats() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  Future<void> _loadUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      nickname = userDoc.data()?['username'] ?? 'User';
      xp = userDoc.data()?['xp'] ?? 0;
      completedModules =
          List<String>.from(userDoc.data()?['completedModules'] ?? []);
    } else {
      print('User document does not exist');
    }
  }

  Future<void> _loadAllModules() async {
    try {
      var fieldsSnapshot =
          await FirebaseFirestore.instance.collection('fields').get();
      List<Map<String, dynamic>> loadedModules = [];

      for (var fieldDoc in fieldsSnapshot.docs) {
        var modulesData = fieldDoc.data()['modules'] as List<dynamic>? ?? [];
        for (var module in modulesData) {
          loadedModules.add({
            'title': module['title'] ?? 'Unknown Module',
            'status': 'NOT FINISHED'
          });
        }
      }

      // Ensure all modules are included
      if (!loadedModules
          .any((module) => module['title'] == 'Reading Comprehension')) {
        loadedModules.add({
          'title': 'Reading Comprehension',
          'status': 'NOT FINISHED',
        });
      }

      if (!loadedModules
          .any((module) => module['title'] == 'Word Pronunciation')) {
        loadedModules.add({
          'title': 'Word Pronunciation',
          'status': 'NOT FINISHED',
        });
      }

      if (!loadedModules
          .any((module) => module['title'] == 'Sentence Composition')) {
        loadedModules.add({
          'title': 'Sentence Composition',
          'status': 'NOT FINISHED',
        });
      }

      if (!loadedModules
          .any((module) => module['title'] == 'Vocabulary Skills')) {
        loadedModules.add({
          'title': 'Vocabulary Skills',
          'status': 'NOT FINISHED',
        });
      }

      await _fetchModuleStatuses(loadedModules);
      setState(() {
        allModules = loadedModules;
      });
    } catch (e) {
      print('Error loading all modules: $e');
    }
  }

  Future<void> _fetchModuleStatuses(List<Map<String, dynamic>> modules) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    for (var module in modules) {
      var moduleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(module['title'])
          .get();

      if (moduleDoc.exists) {
        var data = moduleDoc.data() as Map<String, dynamic>;
        module['status'] = data['status'] ?? 'NOT FINISHED';
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getRandomModules() async {
    var rng = Random();
    List<Map<String, dynamic>> randomModules = [];

    if (allModules.isNotEmpty) {
      allModules.shuffle(rng);
      randomModules = allModules.take(3).toList(); // Changed to 3 modules
    }

    return randomModules;
  }

  void _navigateToQuiz(Map<String, dynamic> module) {
    String moduleTitle = module['title'];

    if (moduleTitle == 'Reading Comprehension') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReadingComprehensionLevels(),
        ),
      );
    } else if (moduleTitle == 'Word Pronunciation') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordPronunciationLevels(),
        ),
      );
    } else if (moduleTitle == 'Sentence Composition') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SentenceCompositionLevels(),
        ),
      );
    } else if (moduleTitle == 'Vocabulary Skills') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VocabularySkillsLevels(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown module type.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        return true; // Exit the app when back is pressed
      },
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
          stream: _fetchUserStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              nickname = data['username'] ?? 'User';
              xp = data['xp'] ?? 0;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[900]!, Colors.blue[700]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.05), // Increased vertical padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Welcome, $nickname!',
                            style: GoogleFonts.montserrat(
                              fontSize: width * 0.06,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HelpPage()),
                              );
                            },
                            child: const Icon(
                              Icons.help,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ranking: #1/4',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          Text('XP Earned: $xp',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          Text(
                            'Modules Completed: ${completedModules.length}/4',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Recommended Modules',
                        style: GoogleFonts.montserrat(
                            fontSize: width * 0.05, color: Colors.white)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getRandomModules(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty) {
                            return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                var module = snapshot.data![index];

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          module['title'],
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Status: ${module['status']}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _navigateToQuiz(module),
                                  ),
                                );
                              },
                            );
                          }
                          return const Center(
                              child: Text('No modules available.'));
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('User document does not exist.'));
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Modules'),
        BottomNavigationBarItem(
            icon: Icon(Icons.menu_book), label: 'Dictionary'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      currentIndex: 0, // Set correctly based on the current page
      selectedItemColor: Colors.blue[900],
      unselectedItemColor: Colors.lightBlue,
      backgroundColor: Colors.white,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on Home, do nothing
            break;
          case 1:
            Navigator.pushNamed(context, '/modules_menu');
            break;
          case 2:
            Navigator.pushNamed(context, '/dictionary_menu');
            break;
          case 3:
            Navigator.pushNamed(context, '/profile_menu');
            break;
          case 4:
            Navigator.pushNamed(context, '/settings_menu');
            break;
        }
      },
    );
  }
}
