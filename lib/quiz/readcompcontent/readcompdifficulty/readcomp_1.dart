import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../mainmenu/modules_menu.dart';

class Question {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String shortStory;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.shortStory,
  });
}

class ReadCompQuiz extends StatefulWidget {
  final String moduleTitle;
  final String difficulty;
  final List<String> uniqueIds;

  const ReadCompQuiz({
    super.key,
    required this.moduleTitle,
    required this.difficulty,
    required this.uniqueIds,
  });

  @override
  _ReadCompQuizState createState() => _ReadCompQuizState();
}

class _ReadCompQuizState extends State<ReadCompQuiz> {
  int score = 0;
  int mistakes = 0;
  List<Question> questions = [];
  bool isLoading = true;
  bool isAnswerSubmitted = false;
  bool hasEarnedXP = false; // Track if XP has been earned
  int selectedAnswerIndex = -1; // Track the selected answer index

  Question? currentQuestion;
  int currentQuestionIndex = 0;
  late Timer _timer;
  int _remainingTime = 300; // 5 minutes for each question
  bool isCalculatingResults = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      if (widget.uniqueIds.isNotEmpty) {
        String uniqueId = widget.uniqueIds[0]; // Use the first unique ID

        final querySnapshot = await FirebaseFirestore.instance
            .collection('fields')
            .doc('Reading Comprehension')
            .collection(widget.difficulty)
            .doc(uniqueId)
            .get();

        if (querySnapshot.exists) {
          final data = querySnapshot.data();
          if (data != null && data['modules'] != null) {
            var modulesData = data['modules'] as List<dynamic>;
            if (modulesData.isNotEmpty) {
              var questionsData = modulesData[0]['questions'] as List<dynamic>;
              for (var questionData in questionsData) {
                var question = Question(
                  questionText: questionData['question'],
                  options: List<String>.from(questionData['options']),
                  correctAnswer: questionData['correctAnswer'],
                  shortStory: questionData['shortStory'],
                );
                questions.add(question);
              }
            }
          }
        } else {
          _showErrorDialog('No unique IDs available.');
        }
      } else {
        _showErrorDialog('No unique IDs available.');
      }
    } catch (e) {
      _showErrorDialog('Failed to load questions. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _remainingTime = 300; // Reset timer for every question
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        _timer.cancel();
        _submitAnswer(); // Automatically submit when time runs out
      }
    });
  }

  void _submitAnswer() {
    if (!isAnswerSubmitted) {
      final correctAnswer = questions[currentQuestionIndex].correctAnswer;

      if (questions[currentQuestionIndex].options[selectedAnswerIndex] ==
          correctAnswer) {
        score++;
      } else {
        mistakes++;
      }

      setState(() {
        isAnswerSubmitted = true;
      });
      _timer.cancel(); // Stop the timer when an answer is submitted
    }
  }

  void _nextQuestion() {
    if (isAnswerSubmitted) {
      setState(() {
        selectedAnswerIndex = -1; // Reset selected answer for the next question
        isAnswerSubmitted = false; // Reset answer submission state
      });

      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
        _startTimer(); // Restart timer for the next question
      } else {
        _calculateResults(); // Calculate results when no more questions
      }
    }
  }

  Future<void> _calculateResults() async {
    setState(() {
      isCalculatingResults = true;
    });

    String userId = FirebaseAuth.instance.currentUser!.uid;
    String difficultyDocId =
        '$userId-Reading Comprehension-${widget.difficulty}'; // Unique ID for the difficulty document

    // Check if the status is already COMPLETED
    DocumentSnapshot difficultyDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(widget.moduleTitle)
        .collection('difficulty')
        .doc(difficultyDocId)
        .get();

    bool isCompleted = difficultyDoc.exists &&
        (difficultyDoc.data() as Map<String, dynamic>)['status'] == 'COMPLETED';

    // Update the existing difficulty document instead of the module
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(widget.moduleTitle)
        .collection('difficulty')
        .doc(difficultyDocId)
        .set({
      'status': 'COMPLETED', // Mark as completed
      'mistakes': mistakes, // Add mistakes
      'time': 0, // Replace 0 with actual time taken if available
    }, SetOptions(merge: true));

    // Check if user has already earned XP
    if (!hasEarnedXP && !isCompleted) {
      // Update XP
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'xp': FieldValue.increment(500),
      });
      hasEarnedXP = true; // Set to true to prevent re-earning XP
    }

    // Add to completed modules (optional, can be removed if not needed)
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'completedModules': FieldValue.arrayUnion([widget.moduleTitle]),
    });

    setState(() {
      isCalculatingResults = false;
    });

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blue, // Set background color
          title: Text(
            '${widget.moduleTitle} Quiz Complete',
            style:
                GoogleFonts.montserrat(color: Colors.white), // White text color
          ),
          content: Text(
            'Score: $score/${questions.length}\nMistakes: $mistakes\nXP Earned: ${hasEarnedXP ? 500 : 0}',
            style:
                GoogleFonts.montserrat(color: Colors.white), // White text color
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModulesMenu(
                      onModulesUpdated: (List<String> updatedModules) {},
                    ),
                  ),
                );
              },
              child: Text(
                'Done',
                style: GoogleFonts.montserrat(
                    color: Colors.white), // White text color
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
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quiz', style: GoogleFonts.montserrat()),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          actions: [
            Icon(Icons.access_time),
            const SizedBox(width: 10),
            Text(
              '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity, // Fill the entire screen
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003366), Color(0xFF0052CC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : questions.isEmpty
                  ? const Center(child: Text('No questions available.'))
                  : isCalculatingResults
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          // Make the content scrollable
                          child: _buildQuizContent(),
                        ),
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    final question = questions[currentQuestionIndex].questionText;
    final options = questions[currentQuestionIndex].options;
    final shortStory = questions[currentQuestionIndex].shortStory;

    String feedbackMessage = '';
    Icon feedbackIcon = Icon(Icons.check, color: Colors.green);
    Color feedbackColor = Colors.green;

    if (isAnswerSubmitted) {
      if (questions[currentQuestionIndex].options[selectedAnswerIndex] ==
          questions[currentQuestionIndex].correctAnswer) {
        feedbackMessage = 'You are correct!';
      } else {
        feedbackMessage = 'Not quite right.';
        feedbackIcon = Icon(Icons.close, color: Colors.red);
        feedbackColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20.0), // Padding around the content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            shortStory,
            style: GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            question,
            style: GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Column(
            children: options.map<Widget>((option) {
              int optionIndex = options.indexOf(option);
              bool isSelected = optionIndex == selectedAnswerIndex;
              bool isCorrectOption =
                  questions[currentQuestionIndex].correctAnswer == option;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton(
                  onPressed: isAnswerSubmitted
                      ? null
                      : () {
                          setState(() {
                            selectedAnswerIndex = optionIndex;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAnswerSubmitted
                        ? (isCorrectOption
                            ? Colors.green
                            : (isSelected
                                ? Colors.orange[800]
                                : Colors.blueAccent))
                        : (isSelected ? Colors.orange[800] : Colors.blueAccent),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (isAnswerSubmitted) // Show feedback only after submission
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                feedbackIcon,
                const SizedBox(width: 8),
                Text(
                  feedbackMessage,
                  style: TextStyle(color: feedbackColor, fontSize: 16),
                ),
              ],
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (isAnswerSubmitted) ? _nextQuestion : _submitAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(
              isAnswerSubmitted ? 'Next' : 'Submit',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
