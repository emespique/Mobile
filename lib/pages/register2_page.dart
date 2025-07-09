import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/form_data.dart';
import '../mainmenu/home_menu.dart';

class PersonalInfoPage extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const PersonalInfoPage({
    super.key,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _strandController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final List<String> strands = [
    'Technical-Vocational-Livelihood (TVL)',
    'Humanities and Social Sciences (HUMSS)',
    'Accountancy, Business, & Management (ABM)',
  ];

  @override
  void initState() {
    super.initState();
    // Load values from FormData
    _fullNameController.text = FormData().fullName;
    _strandController.text = FormData().strand;
    _birthdayController.text = FormData().birthday;
    _addressController.text = FormData().address;

    // Add listeners to save input in real-time
    _fullNameController.addListener(() {
      FormData().fullName = _fullNameController.text;
    });
    _strandController.addListener(() {
      FormData().strand = _strandController.text;
    });
    _birthdayController.addListener(() {
      FormData().birthday = _birthdayController.text;
    });
    _addressController.addListener(() {
      FormData().address = _addressController.text;
    });
  }

  Future<void> _selectBirthday(BuildContext context) async {
    DateTime firstDate = DateTime(2003, 1, 1);
    DateTime lastDate = DateTime(2007, 12, 31);
    DateTime initialDate =
        DateTime.now().isBefore(lastDate) ? DateTime.now() : lastDate;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogBackgroundColor: Colors.blue[700],
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
              headlineMedium: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    String formattedDate = DateFormat('MM/dd/yyyy').format(pickedDate!);
    setState(() {
      _birthdayController.text = formattedDate;
    });
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Your Information'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Email: ${widget.emailController.text}'),
                Text('Username: ${widget.usernameController.text}'),
                Text('Password: ${widget.passwordController.text}'),
                Text('Full Name: ${_fullNameController.text}'),
                Text('Strand: ${_strandController.text}'),
                Text('Birthday: ${_birthdayController.text}'),
                Text('Address: ${_addressController.text}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSignUp();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSignUp() async {
    if (_fullNameController.text.isEmpty ||
        _strandController.text.isEmpty ||
        _birthdayController.text.isEmpty ||
        _addressController.text.isEmpty ||
        widget.emailController.text.isEmpty ||
        widget.usernameController.text.isEmpty ||
        widget.passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.emailController.text,
        password: widget.passwordController.text,
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': _fullNameController.text,
        'username': widget.usernameController.text,
        'strand': _strandController.text,
        'birthday': _birthdayController.text,
        'address': _addressController.text,
        'email': widget.emailController.text,
        'uniqueCode': FormData().uniqueCode, // Add unique code here
        'downloadedModules': [],
        'completedModules': [],
        'xp': 0,
      });

      await _initializeModuleProgress(uid);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              const HomeMenu(uniqueIds: []), // Pass uniqueIds here if needed
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _initializeModuleProgress(String uid) async {
    // Define the modules and their corresponding difficulties
    const moduleDifficulties = {
      'Reading Comprehension': ['Easy', 'Medium', 'Hard'],
      'Sentence Composition': ['Easy', 'Medium', 'Hard'],
      'Vocabulary Skills': ['Easy', 'Medium', 'Hard'],
      'Word Pronunciation': ['Easy', 'Medium', 'Hard'],
    };

    for (var moduleName in moduleDifficulties.keys) {
      try {
        // Create the module progress document for the user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(moduleName)
            .set({
          'status': 'NOT STARTED',
        });

        // Get the difficulties for the current module
        var difficulties = moduleDifficulties[moduleName]!;

        for (String difficultyName in difficulties) {
          // Create a unique ID based on the user ID and difficulty name
          String uniqueId =
              '$uid-$moduleName-$difficultyName'; // e.g., userId-Reading Comprehension-Easy

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('progress')
              .doc(moduleName)
              .collection('difficulty')
              .doc(uniqueId) // Use the dynamically created unique ID
              .set({
            'status': 'NOT STARTED',
          });
        }
      } catch (e) {
        print('Error initializing module progress for $moduleName: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                "Personify Yourself!",
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Add in your personal details here',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Full Name Field
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter Full Name here...',
                icon: Icons.person,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\d')),
                ],
                maxLength: 30, // Set max length for Full Name
              ),
              const SizedBox(height: 20),

              // Strand ComboBox with Icon
              _buildDropdownField(
                controller: _strandController,
                label: 'Strand',
                items: strands,
              ),
              const SizedBox(height: 20),

              // Birthday Field
              GestureDetector(
                onTap: () => _selectBirthday(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _birthdayController,
                    label: 'Birthday (MM/DD/YYYY)',
                    hint: 'MM/DD/YYYY...',
                    icon: Icons.calendar_today,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Barangay, City...',
                icon: Icons.location_on,
                maxLength: 50, // Set max length for Address
              ),
              const SizedBox(height: 20),

              // Sign Up Button
              ElevatedButton(
                onPressed: _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Terms and Conditions
              RichText(
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  children: [
                    const TextSpan(text: 'By signing up, you agree to\n'),
                    TextSpan(
                      text: 'I-READ\'s Terms of Service and Privacy Policy.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Define action for tapping the terms link
                        },
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Full Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.grey[400],
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.blue[800]?.withOpacity(0.3),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[800]!),
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white),
      ),
      style: GoogleFonts.montserrat(color: Colors.white),
      inputFormatters: inputFormatters,
      buildCounter: (context,
          {required currentLength, maxLength, required isFocused}) {
        return null; // Hides the character limit
      },
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required List<String> items,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.blue[800]?.withOpacity(0.3),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[800]!),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.text.isEmpty ? null : controller.text,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isExpanded: true,
          items: items.map((String strand) {
            return DropdownMenuItem<String>(
              value: strand,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        strand,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              controller.text = newValue!;
            });
          },
          dropdownColor: Colors.blue[800]?.withOpacity(0.9),
          style: GoogleFonts.montserrat(color: Colors.white),
          hint: const Text('Select Strand',
              style: TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}
