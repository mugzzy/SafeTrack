import 'package:flutter/material.dart';

class StudentNotificationPage extends StatelessWidget {
  const StudentNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Notifications")),
      body: const Center(
        child: Text(
          'This is the student notification page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
