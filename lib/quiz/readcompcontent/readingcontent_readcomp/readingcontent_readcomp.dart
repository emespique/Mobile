import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../readcompdifficulty/readcomp_1.dart';

class ReadingContentPageReadComp1 extends StatelessWidget {
  final String level;
  final List<String> uniqueIds;

  const ReadingContentPageReadComp1({
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
            Text('Reading Content - $level', style: GoogleFonts.montserrat()),
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
                'Here is where you will display the reading content for the $level level.',
                style:
                    GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 40), // Space before the button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Removed the debug print statement
                    // Navigate to the quiz page when the button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadCompQuiz(
                          moduleTitle: 'Reading Comprehension',
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
                    'Play the quiz!',
                    style: GoogleFonts.montserrat(
                      color: Colors.white, // Change button text color to white
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildContentBasedOnDifficulty(
                  difficulty), // Call to display content based on difficulty
            ],
          ),
        ),
      ),
    );
  }

  String determineDifficulty(List<String> uniqueIds) {
    // Determine the difficulty based on unique IDs
    if (uniqueIds.contains('myoLYQD0ML1gWuSI0t1U')) {
      return 'Easy';
    } else if (uniqueIds.contains('2jOvLgO48hHIMAwpi1qx')) {
      return 'Medium';
    } else if (uniqueIds.contains('JBTrWkZJjYfSSwvQUl9Z')) {
      return 'Hard';
    }
    return 'Unknown'; // Default case
  }

  Widget _buildContentBasedOnDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Text(
          'Easy content: Here are some simple reading exercises.',
          style: GoogleFonts.montserrat(color: Colors.white),
        );
      case 'Medium':
        return Text(
          'Medium content: Here are some moderately challenging reading exercises.',
          style: GoogleFonts.montserrat(color: Colors.white),
        );
      case 'Hard':
        return Text(
          'Hard content: Here are advanced reading exercises to challenge your skills.',
          style: GoogleFonts.montserrat(color: Colors.white),
        );
      default:
        return Text(
          'No content available for this difficulty level.',
          style: GoogleFonts.montserrat(color: Colors.white),
        );
    }
  }
}
