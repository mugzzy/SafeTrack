import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
      ),
      body: Center(
        child: const Text(
          'This is the Attendance page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
