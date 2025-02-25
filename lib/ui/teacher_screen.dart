import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';

import '../../models/event_model.dart'; // Import EventModel
import '../../services/audit_log_service.dart'; // Import the AuditLogService
import '../services/presence_service.dart';
import 'teacher_pages/add_content.dart';
import 'teacher_pages/calendar.dart';
import 'teacher_pages/custom_navbar.dart'; // Import the custom bottom navigation bar
import 'teacher_pages/teacher_home.dart';
import 'teacher_pages/teacher_more.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _currentIndex = 1; // Default index for the Home page
  final AuditLogService _auditLogService = AuditLogService();
  EventModel? _selectedEvent; // Store selected event details

  List<Widget> get _pages {
    return [
      CalendarPage(onEventSelected: _onEventSelected),
      TeacherHome(eventId: _selectedEvent?.eventId ?? ''),
      const AddContentPage(),
      const TeacherMorePage(),
    ];
  }

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

  void _onEventSelected(EventModel event) {
    setState(() {
      _selectedEvent = event; // Update the selected event
      _currentIndex = 1; // Switch to the TeacherHome page
    });
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
      body: _pages[_currentIndex], // Display the current page
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
