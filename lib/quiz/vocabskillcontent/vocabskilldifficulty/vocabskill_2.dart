import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VocabSkillsQuiz2 extends StatefulWidget {
  final String moduleTitle;

  const VocabSkillsQuiz2(
      {super.key,
      required this.moduleTitle,
      required List<String> uniqueIds,
      required String difficulty});

  @override
  _VocabSkillsQuiz2State createState() => _VocabSkillsQuiz2State();
}

class _VocabSkillsQuiz2State extends State<VocabSkillsQuiz2> {
  int currentQuestionIndex = 0;
  int score = 0;
  int mistakes = 0;
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  bool isAnswerSelected = false;
  int selectedAnswerIndex = -1; // Track selected option
  String feedbackMessage = '';
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fields')
          .doc('Vocabulary Skills') // Update this as needed
          .collection('Medium') // Adjust this as needed
          .doc('JeGtBN3k2Ni4LAVAY2z7') // Replace with your unique ID
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['modules'] != null) {
          var modules = List<Map<String, dynamic>>.from(data['modules']);
          if (modules.isNotEmpty) {
            var questionsData = modules[0]['questions'] ?? [];
            questions = List<Map<String, dynamic>>.from(questionsData);
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Error loading questions: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _submitAnswer() {
    final correctAnswer = questions[currentQuestionIndex]['correctAnswer'];

    if (questions[currentQuestionIndex]['options'][selectedAnswerIndex] ==
        correctAnswer) {
      setState(() {
        score++;
        feedbackMessage = "You are correct!";
        isCorrect = true;
      });
    } else {
      mistakes++;
      feedbackMessage = "Incorrect answer. Please try again.";
      isCorrect = false;
    }

    setState(() {
      isAnswerSelected = true; // Show feedback after submission
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        isAnswerSelected = false; // Reset for the next question
        selectedAnswerIndex = -1; // Reset the selected answer
        feedbackMessage = ''; // Clear feedback
      });
    } else {
      _showResults();
    }
  }

  Future<void> _showResults() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String moduleTitle = widget.moduleTitle;
    String difficulty = 'Medium'; // Adjust as necessary

    // Define the unique document ID for the specific difficulty
    String difficultyDocId =
        '$userId-$moduleTitle-$difficulty'; // Updated unique ID format

    // Update user's progress for the specific difficulty
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(moduleTitle)
        .collection('difficulty')
        .doc(difficultyDocId)
        .set({
      'status': 'COMPLETED', // Set status to uppercase
      'mistakes': mistakes,
      'time': 0, // Add any other relevant fields as needed
    }, SetOptions(merge: true));

    // Update user XP in the users collection
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'xp': FieldValue.increment(500), // Increment XP
    });

    // Add module to completedModules
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'completedModules': FieldValue.arrayUnion([moduleTitle]),
    });

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blue,
          title: Text(
            '$moduleTitle Quiz Complete',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          content: Text(
            'Score: $score/${questions.length}\nMistakes: $mistakes\nXP Earned: 500',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pop(context); // Return to modules menu
              },
              child: Text(
                'Done',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // Return to previous screen
        return false; // Prevent default back action
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.moduleTitle, style: GoogleFonts.montserrat()),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : questions.isEmpty
                ? const Center(
                    child: Text('No questions available.',
                        style: TextStyle(fontSize: 18)))
                : _buildQuizContent(),
      ),
    );
  }

  Widget _buildQuizContent() {
    final question = questions[currentQuestionIndex]['question'];
    final options = questions[currentQuestionIndex]['options'];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF0052CC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment:
              MainAxisAlignment.center, // Center the content vertically
          children: [
            Text(
              question,
              style: GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Column(
              children: options.map<Widget>((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedAnswerIndex = options.indexOf(option);
                        feedbackMessage = ''; // Reset feedback message
                        isAnswerSelected = false; // Allow resubmission
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedAnswerIndex == options.indexOf(option)
                              ? Colors.orange // Color for selected options
                              : Colors.blue[700], // Updated button color
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      option,
                      style: GoogleFonts.montserrat(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (isAnswerSelected) {
                  // If an answer has been selected, check if it's correct
                  if (isCorrect) {
                    _nextQuestion(); // Go to the next question if correct
                  } else {
                    // If incorrect, allow the user to select another option
                    setState(() {
                      feedbackMessage = ''; // Clear feedback
                      isAnswerSelected = false; // Reset for new selection
                      selectedAnswerIndex = -1; // Reset the selection
                    });
                  }
                } else if (selectedAnswerIndex != -1) {
                  _submitAnswer(); // Submit answer if selected
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Updated color for Submit button
                minimumSize: const Size(150, 40),
              ),
              child: Text(
                isCorrect ? 'Next' : 'Submit',
                style: GoogleFonts.montserrat(
                    color: Colors.white), // Change text color to white
              ),
            ),
            const SizedBox(height: 20),
            if (isAnswerSelected) ...[
              Text(
                feedbackMessage,
                style: TextStyle(
                  color: isCorrect
                      ? const Color(0xFF00FF00)
                      : const Color(0xFFFF6666),
                  fontSize: 18, // Made feedback message smaller
                ),
              ),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect
                    ? const Color(0xFF00FF00)
                    : const Color(0xFFFF6666),
                size: 60,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
