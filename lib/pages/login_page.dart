import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firestore/firestore_user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirestoreUser _firestoreUser = FirestoreUser();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  String? _emailError;
  String? _passwordError;

  bool _isEmailValid(String email) {
    final emailRegExp =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegExp.hasMatch(email);
  }

  void _validateEmail(String value) {
    if (value.isNotEmpty) {
      if (!_isEmailValid(value)) {
        setState(() {
          _emailError = 'Please input a valid email';
        });
      } else {
        setState(() {
          _emailError = null; // Clear error
        });
      }
    } else {
      setState(() {
        _emailError = null; // No error message for empty input
      });
    }
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8;
  }

  void _validatePassword(String value) {
    if (value.isNotEmpty) {
      if (!_isPasswordValid(value)) {
        setState(() {
          _passwordError = 'Please input at least 8 characters';
        });
      } else {
        setState(() {
          _passwordError = null; // Clear error
        });
      }
    } else {
      setState(() {
        _passwordError = null; // No error message for empty input
      });
    }
  }

  void _handleLogin() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    _validateEmail(email);
    _validatePassword(password);

    if (_emailError == null && _passwordError == null) {
      try {
        await _firestoreUser.signIn(
            email, password); // Use FirestoreUser for login
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please input a registered user account')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.05,
          vertical: height * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: 400), // Max width for larger screens
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Change here
                  children: [
                    Image.asset('assets/i_read_pic.png',
                        width: 120, height: 120),
                    const SizedBox(height: 20),
                    const Text('where learning gets better.',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white, thickness: 1),
                    const SizedBox(height: 20),
                    Text('Login',
                        style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      maxLength: 30,
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.blue[800]?.withOpacity(0.3),
                        border: const OutlineInputBorder(),
                        hintText: 'Enter E-mail here...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.white),
                        counterText: '', // Set counterText to an empty string
                      ),
                      style: GoogleFonts.montserrat(color: Colors.white),
                      onChanged: _validateEmail,
                    ),
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_emailError!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 20),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.blue[800]?.withOpacity(0.3),
                        border: const OutlineInputBorder(),
                        hintText: 'Enter password here...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        counterText: '', // Set counterText to an empty string
                      ),
                      style: GoogleFonts.montserrat(color: Colors.white),
                      onChanged: _validatePassword,
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_passwordError!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text('Login',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.montserrat(color: Colors.white),
                        children: [
                          const TextSpan(text: "Don't have an Account? "),
                          TextSpan(
                            text: 'Sign Up here.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/register');
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
