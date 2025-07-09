import 'package:flutter/material.dart';
import 'package:i_read_app/functions/editprofilepage.dart';
import 'firebase_options.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'mainmenu/home_menu.dart';
import 'mainmenu/modules_menu.dart';
import 'mainmenu/dictionary_menu.dart';
import 'mainmenu/profile_menu.dart';
import 'mainmenu/settings_menu.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-READ App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) =>
            HomeMenu(uniqueIds: []), // Pass an empty list or actual unique IDs
        '/modules_menu': (context) => ModulesMenu(
              onModulesUpdated: (updatedModules) {},
            ),
        '/dictionary_menu': (context) => const DictionaryMenu(),
        '/profile_menu': (context) => const ProfileMenu(),
        '/settings_menu': (context) => const SettingsMenu(),
        '/editprofilepage': (context) => const EditProfilePage(),
      },
    );
  }
}
