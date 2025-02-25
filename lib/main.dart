import 'package:capstone_1/models/user_model.dart';
import 'package:capstone_1/ui/admin_pages/admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'ui/login_screen.dart';
import 'ui/parent_screen.dart';
import 'ui/student_screen.dart';
import 'ui/teacher_screen.dart';
import 'ui/welcome_screen.dart'; // Ensure you have this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DefaultFirebaseOptions.initializeFirebase(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define named routes for easy navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const Wrapper(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        // Add other screens if necessary
      },
    );
  }
}

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserDetails(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasData) {
                final role = userSnapshot.data!.role;
                Widget targetScreen;

                switch (role) {
                  case 'Student':
                    targetScreen = const StudentScreen();
                    break;
                  case 'Parent':
                    targetScreen = const ParentScreen();
                    break;
                  case 'Teacher':
                    targetScreen = const TeacherScreen();
                    break;
                  case 'Admin':
                    targetScreen = const AdminScreen();
                    break;
                  default:
                    targetScreen = const Center(child: Text('Unknown role'));
                }

                return targetScreen;
              } else {
                return const LoginScreen(); // Show LoginScreen if no user data
              }
            },
          );
        } else {
          return const WelcomeScreen(); // Show WelcomeScreen for unauthenticated users
        }
      },
    );
  }
}
