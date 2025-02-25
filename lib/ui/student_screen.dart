import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';
import '../services/presence_service.dart';
import 'student_pages/custom_navbar.dart';
import 'student_pages/student_home.dart';
import 'student_pages/student_messages.dart';
import 'student_pages/student_more.dart';
import 'student_pages/student_profile.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _currentIndex = 0;
  final AuditLogService _auditLogService = AuditLogService();

  final List<Widget> _pages = [
    const StudentHomePage(),
    const StudentProfilePage(),
    const StudentMessagesPage(),
    StudentMorePage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
