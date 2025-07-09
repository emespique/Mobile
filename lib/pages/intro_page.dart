import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.05, vertical: height * 0.02),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo at the top
              Image.asset(
                'assets/i_read_pic.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 20),

              // Text content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Text(
                      'Text got you stressed?\nSentences sinking your ship?\nI-READ is your superhero!',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'This app blasts you off on a reading adventure, transforming you into a word-wielding, grammar-grasping champion.',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Get ready to conquer comprehension and pronunciation with I-READ!',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const RegisterPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Get Started!',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: Colors.grey[400],
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
