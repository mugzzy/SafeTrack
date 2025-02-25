import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'audit_log_service.dart';

class LogoutService {
  final AuditLogService _auditLogService = AuditLogService();

  Future<void> logout(BuildContext context, String role) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        // Log the activity before signing out
        await _auditLogService.logActivity(
          userDoc['username'] ?? 'N/A',
          currentUser.email ?? 'N/A',
          role,
          'logged out',
          'User logged out',
        );
      }

      await FirebaseAuth.instance.signOut();
      _showPopup(context, 'Signed out successfully!', isSuccess: true);
    } catch (e) {
      _showPopup(context, 'Sign out failed. Please try again.', isSuccess: false);
    }
  }

  void _showPopup(BuildContext context, String message, {bool isSuccess = true}) {
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
}
