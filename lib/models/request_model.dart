import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String parentName;
  final String childAccountId;
  final String status;
  final DateTime timestamp;

  RequestModel({
    required this.id,
    required this.parentName,
    required this.childAccountId,
    required this.status,
    required this.timestamp,
  });

  factory RequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe parsing with null checks
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

    return RequestModel(
      id: doc.id,
      parentName: data['parentName'] ??
          'Unknown', // Default value for missing parent name
      childAccountId: data['studentID'] ??
          '', // Default empty string for missing child account ID
      status:
          data['status'] ?? 'Pending', // Default 'Pending' if status is missing
      timestamp: timestamp?.toDate() ??
          DateTime.now(), // Default to current time if timestamp is null
    );
  }
}
