import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../vocabskilldifficulty/vocabskill_1.dart';

class ReadingContentPageVocabSkill1 extends StatelessWidget {
  final String level;
  final List<String> uniqueIds;

  const ReadingContentPageVocabSkill1({
    super.key,
    required this.level,
    required this.uniqueIds,
  });

  @override
  Widget build(BuildContext context) {
    String difficulty = determineDifficulty(uniqueIds); // Determine difficulty

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title:
            Text('Vocabulary Skills - $level', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white, // Set text color to white
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Topic Title',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Change text color to white
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white, thickness: 2), // Underline
              const SizedBox(height: 20),
              Text(
                'Here is where you will display the vocabulary skills content for the $level level.',
                style:
                    GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 40), // Space before the button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    print('Unique IDs: $uniqueIds'); // Debug print
                    // Navigate to the Word Pro quiz page when the button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VocabSkillsQuiz(
                          moduleTitle: 'Word Pro Quiz',
                          difficulty:
                              difficulty, // Pass the actual difficulty level
                          uniqueIds: uniqueIds,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900], // Change button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'Start the Vocabulary Quiz!',
                    style: GoogleFonts.montserrat(
                      color: Colors.white, // Change button text color to white
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

  String determineDifficulty(List<String> uniqueIds) {
    // Determine the difficulty based on unique IDs
    if (uniqueIds.contains('sPB0TBLavMJimWriirGr')) {
      return 'Easy';
    } else if (uniqueIds.contains('DKWdld9O5Iu3yfMkmO00')) {
      return 'Medium';
    } else if (uniqueIds.contains('0gDRHXVKhjGmlDj993DQ')) {
      return 'Hard';
    }
    return 'Unknown'; // Default case
  }
}
