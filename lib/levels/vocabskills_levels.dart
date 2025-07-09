import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../indevelop.dart';
import '../quiz/vocabskillcontent/vocabskilldifficulty/vocabskill_1.dart';

class VocabularySkillsLevels extends StatefulWidget {
  const VocabularySkillsLevels({super.key});

  @override
  _VocabularySkillsLevelsState createState() => _VocabularySkillsLevelsState();
}

class _VocabularySkillsLevelsState extends State<VocabularySkillsLevels> {
  String userId = '';
  final String easyId = 'sOOI4k8t4pzArVZkKG3f'; // Easy unique ID
  final String mediumId = 'JeGtBN3k2Ni4LAVAY2z7'; // Medium unique ID
  final String hardId = '7bdxc9Mr3F46ywnt7mRt'; // Hard unique ID

  bool isEasyCompleted = false;
  bool isMediumCompleted = false;
  bool isHardCompleted = false;

  @override
  void initState() {
    super.initState();
    _getUserId().then((id) {
      setState(() {
        userId = id;
      });
      _checkCompletionStatus();
    });
  }

  Future<void> _checkCompletionStatus() async {
    await _checkDifficultyStatus(userId, easyId).then((completed) {
      setState(() {
        isEasyCompleted = completed; // Track completion for Easy
      });
    });

    await _checkDifficultyStatus(userId, mediumId).then((completed) {
      setState(() {
        isMediumCompleted = completed; // Track completion for Medium
      });
    });

    await _checkDifficultyStatus(userId, hardId).then((completed) {
      setState(() {
        isHardCompleted = completed; // Track completion for Hard
      });
    });
  }

  Future<String> _getUserId() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      return user?.uid ??
          ''; // Return the user ID or an empty string if not found
    } catch (e) {
      print('Error fetching user ID: $e');
      return ''; // Default to an empty string
    }
  }

  Future<bool> _checkDifficultyStatus(
      String userId, String difficultyId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('Vocabulary Skills')
          .collection('difficulty')
          .doc(difficultyId)
          .get();

      if (snapshot.exists) {
        return snapshot['status'] == 'COMPLETED'; // Return completion status
      }
    } catch (e) {
      print('Error checking difficulty status for $difficultyId: $e');
    }
    return false; // Default to not completed
  }

  Future<void> _updateUserProgress() async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc('Vocabulary Skills')
        .collection('difficulty')
        .doc(easyId); // Use Easy ID for this example

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.set({
          'status': 'COMPLETED',
          'attempts': FieldValue.increment(1) // Increment attempt count
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'status': 'COMPLETED',
          'attempts': 1 // Initial attempt count
        });
      }

      // Update completion status for Easy
      setState(() {
        isEasyCompleted = true; // Mark Easy as completed
        isMediumCompleted = true; // Unlock Medium
      });
    } catch (e) {
      print('Error updating document: $e'); // Optional error logging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Vocabulary Skills Levels', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLevelButton(context, 'Easy', true), // Always unlocked
            const SizedBox(height: 20),
            _buildLevelButton(context, 'Medium',
                isEasyCompleted), // Unlocked if Easy is completed
            const SizedBox(height: 20),
            _buildLevelButton(context, 'Hard',
                isMediumCompleted), // Unlocked if Medium is completed
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(
      BuildContext context, String level, bool isUnlocked) {
    return ElevatedButton(
      onPressed: isUnlocked
          ? () async {
              if (level == 'Easy') {
                // Fetch unique IDs for the Easy level
                List<String> uniqueIds = await _fetchUniqueIds('Easy');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VocabSkillsQuiz(
                      moduleTitle: 'Vocabulary Skills',
                      uniqueIds: uniqueIds, // Pass unique IDs
                      difficulty: 'Easy', // Pass difficulty level
                    ),
                  ),
                ).then((result) {
                  // Handle completion result for Easy level
                  if (result == true) {
                    _updateUserProgress(); // Update progress on completion
                  }
                });
              } else if (level == 'Medium') {
                // Navigate to the Medium content page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DevelopmentScreen(),
                  ),
                ).then((result) {
                  // Handle completion result for Medium level
                  if (result == true) {
                    _onLevelCompleted(level);
                  }
                });
              } else if (level == 'Hard') {
                // Navigate to the Hard content page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DevelopmentScreen(),
                  ),
                ).then((result) {
                  // Handle completion result for Hard level
                  if (result == true) {
                    _onLevelCompleted(level);
                  }
                });
              }
            }
          : null, // Disable button if locked
      style: ElevatedButton.styleFrom(
        backgroundColor: isUnlocked
            ? (level == 'Easy' && isEasyCompleted
                ? Colors.green
                : (level == 'Medium' && isMediumCompleted
                    ? Colors.green
                    : (level == 'Hard' && isHardCompleted
                        ? Colors.green
                        : Colors.blue)))
            : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isUnlocked) ...[
            const Icon(Icons.lock, color: Colors.white),
            const SizedBox(width: 10),
          ],
          Text(
            level,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _fetchUniqueIds(String difficulty) async {
    // Return the unique IDs based on difficulty level
    switch (difficulty) {
      case 'Easy':
        return [easyId];
      case 'Medium':
        return [mediumId];
      case 'Hard':
        return [hardId];
      default:
        return [];
    }
  }

  void _onLevelCompleted(String level) {
    setState(() {
      if (level == 'Easy') {
        isEasyCompleted = true;
      } else if (level == 'Medium') {
        isMediumCompleted = true;
      } else if (level == 'Hard') {
        isHardCompleted = true;
      }
    });
  }
}
