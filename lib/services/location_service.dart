import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper property to get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Helper property to get the current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Method to share the current location by saving it to Firestore
  Future<void> shareLocation(LatLng location) async {
    String? userId = currentUserId;
    String? email = currentUserEmail;
    if (userId != null && email != null) {
      await _db.collection('locations').doc(userId).set({
        'email': email, // Add email as a field
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Stream to get live location updates from Firestore
  Stream<DocumentSnapshot> getLocationUpdates() {
    String? userId = currentUserId;
    if (userId != null) {
      return _db.collection('locations').doc(userId).snapshots();
    }
    return const Stream.empty();
  }

  // Stream to listen to device location changes
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).map((position) {
      updateLocation(position);
      return position;
    });
  }

  // Method to update location in Firestore
  Future<void> updateLocation(Position position) async {
    String? userId = currentUserId;
    String? email = currentUserEmail;
    if (userId != null && email != null) {
      await _db.collection('locations').doc(userId).set({
        'email': email, // Add email as a field
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
