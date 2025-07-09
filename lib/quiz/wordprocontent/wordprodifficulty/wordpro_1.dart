import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../mainmenu/modules_menu.dart';

class WordProQuiz extends StatefulWidget {
  final String moduleTitle;
  final List<String> uniqueIds;
  final String difficulty;

  const WordProQuiz({
    super.key,
    required this.moduleTitle,
    required this.uniqueIds,
    required this.difficulty,
  });

  @override
  _WordProQuizState createState() => _WordProQuizState();
}

class _WordProQuizState extends State<WordProQuiz> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  String recognizedText = '';
  bool isListening = false;
  String feedbackMessage = '';
  IconData feedbackIcon = Icons.help;
  int attemptCounter = 0;
  int mistakes = 0;
  double totalAccuracy = 0;
  double bestAccuracy = 0;
  bool showNextButton = false;
  late String userId;
  Timer? _silenceTimer;
  bool isSpeaking = false;
  bool canProceedToNext = false;
  Timer? _nextButtonTimer;
  bool xpEarned = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      String uniqueId = 'sPB0TBLavMJimWriirGr'; // Adjust this as needed
      final querySnapshot = await FirebaseFirestore.instance
          .collection('fields')
          .doc('Word Pronunciation')
          .collection(widget.difficulty)
          .doc(uniqueId)
          .get();

      if (querySnapshot.exists) {
        final data = querySnapshot.data();
        if (data != null && data['modules'] != null) {
          var modulesData = data['modules'] as List<dynamic>;

          for (var module in modulesData) {
            var questionsData = module['questions'] as List<dynamic>;
            for (var questionData in questionsData) {
              questions.add({
                'question': questionData['question'],
                'correctAnswer': questionData['correctAnswer'],
              });
            }
          }
        }
      }
      if (questions.isNotEmpty) {
        await _speakQuestion();
        setState(() {});
      }
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  Future<void> _speakQuestion() async {
    if (questions.isNotEmpty) {
      setState(() {
        isSpeaking = true;
        recognizedText = '';
      });
      await flutterTts.speak(questions[currentQuestionIndex]['question']);
      flutterTts.setCompletionHandler(() {
        setState(() {
          isSpeaking = false;
          canProceedToNext = true;
        });
      });
    }
  }

  void startListening() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (status.isDenied) {
        setState(() {
          recognizedText = 'Microphone permission denied.';
        });
        return;
      }
    }

    if (!isListening && !isSpeaking) {
      bool available = await speech.initialize();
      if (available) {
        setState(() {
          recognizedText = 'Listening...';
          feedbackMessage = '';
          feedbackIcon = Icons.help;
          showNextButton = false;
          isListening = true;
        });

        speech.listen(onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            setState(() {
              recognizedText = result.recognizedWords;
            });

            _silenceTimer?.cancel();
            _silenceTimer = Timer(Duration(seconds: 3), () {
              speech.stop();
              isListening = false;
              _processRecognizedText();
            });
          }
        });

        // Auto-check after 3 seconds of silence
        _silenceTimer = Timer(Duration(seconds: 3), () {
          if (isListening) {
            speech.stop();
            isListening = false;
            _processRecognizedText();
          }
        });
      } else {
        setState(() {
          recognizedText = 'Speech recognition not available.';
        });
      }
    }
  }

  void _processRecognizedText() {
    if (recognizedText.isNotEmpty) {
      recognizedText =
          recognizedText[0].toUpperCase() + recognizedText.substring(1);
      if (!recognizedText.endsWith('.')) {
        recognizedText += '.';
      }
      checkAnswer(recognizedText);
    }
  }

  Future<void> checkAnswer(String recognizedText) async {
    String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
    int accuracy = _calculateAccuracy(recognizedText, correctAnswer);

    if (accuracy >= 90) {
      setState(() {
        feedbackMessage = 'You are $accuracy% accurate!';
        feedbackIcon = Icons.check_circle;
        attemptCounter = 0;
        totalAccuracy += accuracy;
        if (accuracy > bestAccuracy) {
          bestAccuracy = accuracy.toDouble();
        }
        if (!xpEarned) {
          xpEarned = true;
          _awardXP();
        }
      });
      _nextButtonTimer?.cancel();
      _nextButtonTimer = Timer(Duration(seconds: 2), () {
        setState(() {
          showNextButton = true;
        });
      });
    } else {
      mistakes++;
      attemptCounter++;
      setState(() {
        feedbackMessage = 'You are $accuracy% accurate!';
        feedbackIcon = Icons.cancel;
        if (attemptCounter >= 3) {
          showNextButton = true;
        }
      });
    }
  }

  int _calculateAccuracy(String recognizedText, String correctAnswer) {
    int correctCount = 0;
    List<String> recognizedWords = recognizedText.split(' ');
    List<String> correctWords = correctAnswer.split(' ');

    for (var word in recognizedWords) {
      if (correctWords.contains(word)) {
        correctCount++;
      }
    }

    int accuracy = ((correctCount / correctWords.length) * 100).round();
    return accuracy > 100 ? 100 : accuracy;
  }

  Future<void> _awardXP() async {
    int baseXP = 500;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    try {
      await userRef.set({
        'xp': FieldValue.increment(baseXP),
        'status': 'completed', // Set status to completed when XP is awarded
      }, SetOptions(merge: true));
      await _updateProgress(); // Update the progress after awarding XP
    } catch (e) {
      print('Error updating XP: $e');
    }
  }

  Future<void> _updateProgress() async {
    String uniqueId = '$userId-${widget.moduleTitle}-${widget.difficulty}';
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(widget.moduleTitle) // Module document
        .collection(widget.difficulty) // Difficulty collection
        .doc(uniqueId); // Unique document ID

    try {
      await docRef.set({
        'status': 'COMPLETED', // Set status to COMPLETED
        'mistakes': mistakes,
        'accuracy':
            totalAccuracy / (currentQuestionIndex + 1), // Average accuracy
      }, SetOptions(merge: true)); // Use merge to update existing fields

      // Award XP only on the first attempt
      if (attemptCounter == 0) {
        await _awardXP();
      }
      print('Progress updated for user $userId: COMPLETED');
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  Future<void> _nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1 && canProceedToNext) {
      setState(() {
        currentQuestionIndex++;
        recognizedText = '';
        feedbackMessage = '';
        feedbackIcon = Icons.help;
        attemptCounter = 0;
        showNextButton = false;
        canProceedToNext = false;
      });
      await _speakQuestion();
    } else {
      await _showCompletionScreen();
      if (!xpEarned) {
        await _awardXP(); // Ensure XP is awarded at the end
      }
    }
  }

  Future<void> _showCompletionScreen() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'Quiz Complete!',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontSize: 28),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mistakes: $mistakes',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) =>
                              ModulesMenu(onModulesUpdated: (modules) {})),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Finish',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    speech.stop();
    _silenceTimer?.cancel();
    _nextButtonTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Word Pronunciation', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  questions.isNotEmpty
                      ? questions[currentQuestionIndex]['question']
                      : 'Loading question...',
                  style:
                      GoogleFonts.montserrat(fontSize: 26, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    recognizedText,
                    style: GoogleFonts.montserrat(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: isListening || isSpeaking || showNextButton
                      ? null
                      : startListening,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening || isSpeaking || showNextButton
                          ? Colors.grey
                          : Colors.blue[600],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      isListening ? Icons.mic_off : Icons.mic,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  feedbackMessage,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: feedbackIcon == Icons.check_circle
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                if (showNextButton)
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
