import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/request_model.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkIfAccountExists(String accountId) async {
    try {
      // Assuming you're checking Firestore for the existence of the Account ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection(
              'users') // Or the collection name where student accounts are stored
          .where('studentID', isEqualTo: accountId)
          .limit(1)
          .get();

      // If a document is found, return true (authenticated)
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking account existence: $e');
      return false;
    }
  }

  // Method to send request only if no duplicate exists
  Future<void> sendRequest(String parentEmail, String parentId,
      String accountId, String? parentUsername) async {
    // Check if a pending request already exists
    final existingRequests = await _firestore
        .collection('requests')
        .where('parentemail', isEqualTo: parentEmail)
        .where('parentId', isEqualTo: parentId)
        .where('studentID', isEqualTo: accountId)
        .where('parentusername', isEqualTo: parentUsername)
        .where('status', isEqualTo: 'Pending') // Check only pending requests
        .get();

    if (existingRequests.docs.isEmpty) {
      // No existing pending request found, send a new request
      await _firestore.collection('requests').add({
        'parentemail': parentEmail,
        'parentId': parentId,
        'studentID': accountId,
        'parentusername': parentUsername,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('Request already exists');
    }
  }

  // Get requests by parent
  Stream<List<RequestModel>> getRequestsByParent(String parentId) {
    return _firestore
        .collection('requests')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromDocument(doc))
            .toList());
  }

  // Cancel request functionality
  Future<void> cancelRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'Cancelled',
    });
  }

  Future<String?> getUsernameByParentId(String parentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .get();
      return snapshot.data()?['username']; // Assuming the field is 'username'
    } catch (e) {
      debugPrint('Error fetching username: $e');
      return null;
    }
  }
}
