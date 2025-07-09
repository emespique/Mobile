import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  _ProfileMenuState createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  int xp = 0;
  int completedModules = 0;
  String fullName = ''; // Declare fullName
  String strand = ''; // Declare strand
  String schoolName = 'Tanauan School of Fisheries'; // Declare school name

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          xp = userSnapshot.get('xp') ?? 0;
          completedModules =
              (userSnapshot.get('completedModules') as List).length;
          fullName =
              userSnapshot.get('fullName') ?? 'Unknown User'; // Fetch full name
          strand =
              userSnapshot.get('strand') ?? 'Unknown Strand'; // Fetch strand
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      AssetImage('assets/i_read_pic.png'), // Default image
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  fullName,
                  style: GoogleFonts.montserrat(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  strand,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
              Center(
                child: Text(
                  schoolName, // Add school name here
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text('Statistics',
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Ranking', '#1/100'),
                        ),
                        Expanded(
                          child: _buildStatCard('XP Earned', xp.toString()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: _buildStatCard('Modules Completed',
                          '$completedModules/4'), // Change to /4
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      color: Colors.blue[800],
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(value,
                style:
                    GoogleFonts.montserrat(color: Colors.white, fontSize: 20)),
          ],
        ),
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
      currentIndex: 3,
      selectedItemColor: Colors.blue[900],
      unselectedItemColor: Colors.lightBlue,
      backgroundColor: Colors.white,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/home');
            break;
          case 1:
            Navigator.pushNamed(context, '/modules_menu');
            break;
          case 2:
            Navigator.pushNamed(context, '/dictionary_menu');
            break;
          case 4:
            Navigator.pushNamed(context, '/settings_menu');
            break;
        }
      },
    );
  }
}
