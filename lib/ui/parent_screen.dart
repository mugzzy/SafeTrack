import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart'; // Import the AuditLogService
import '../services/presence_service.dart';
import 'parent_pages/parent_home.dart';
import 'parent_pages/parent_messages.dart';
import 'parent_pages/parent_more.dart';
import 'parent_pages/parent_profile.dart';
import 'parent_pages/custom_navbar.dart'; // Adjust the path accordingly

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  _ParentScreenState createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int _currentIndex = 0;
  final AuditLogService _auditLogService =
      AuditLogService(); // Initialize AuditLogService

  final List<Widget> _pages = [
    const ParentHomePage(),
    const ParentProfilePage(),
    const ParentMessagesPage(),
    const ParentMorePage(),
  ];

  final presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    // Set the user as online when this screen is loaded
    presenceService.updatePresenceOnEnter();
  }

  @override
  void dispose() {
    // Set the user as offline when this screen is closed
    presenceService.stopUpdatingPresence();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch user details from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Log the logout event
        await _auditLogService.logActivity(
          userDoc['username'] ?? 'N/A',
          currentUser.email ?? 'N/A',
          userDoc['role'] ?? 'N/A',
          'logged out',
          'User logged out',
        );
      }

      await FirebaseAuth.instance.signOut();
      print('User signed out successfully.');
      _showPopup(context, 'Signed out successfully!', isSuccess: true);
    } catch (e) {
      print('Sign out error: $e');
      _showPopup(context, 'Sign out failed. Please try again.',
          isSuccess: false);
    }
  }

  void _showPopup(BuildContext context, String message,
      {bool isSuccess = true}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.pushReplacementNamed(context, '/welcome');
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _pages[_currentIndex], // Display the current page based on the index
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Update the index when a new tab is selected
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _signOut(context),
      //   tooltip: 'Sign Out',
      //   child: const Icon(Icons.logout),
      // ),
    );
  }
}
