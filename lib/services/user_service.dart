import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all user accounts with details like username, email, role, and createdAt
  Stream<List<Map<String, dynamic>>> getUserAccounts() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'username': data['username'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? '',
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getChildUserDetails(
      String childAccountId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('studentID', isEqualTo: childAccountId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}
