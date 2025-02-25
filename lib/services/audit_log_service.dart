import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch logs for a specific date
  Stream<List<Map<String, dynamic>>> getAuditLogsByDate(String date) {
    return _firestore
        .collection('auditLogs')
        .doc(date)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Log an activity for the current date
  Future<void> logActivity(String username, String email, String role,
      String status, String activity) async {
    String date = DateTime.now().toLocal().toString().split(' ')[0];
    try {
      await _firestore
          .collection('auditLogs')
          .doc(date)
          .collection('logs')
          .add({
        'username': username,
        'email': email,
        'role': role,
        'activity': activity,
        'status': status,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to log activity: $e');
    }
  }
}
