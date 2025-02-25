import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String email;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Location({
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory Location.fromMap(Map<String, dynamic> data) {
    return Location(
      email: data['email'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}
