import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchAcceptedRequests(
      String userId, Function onChildDetailsFetched) async {
    try {
      final querySnapshot = await _firestore
          .collection('requests')
          .where('parentId', isEqualTo: userId)
          .where('status', isEqualTo: 'Accepted')
          .get();

      for (var doc in querySnapshot.docs) {
        final requestData = doc.data();
        final childAccountId = requestData['studentID'] as String;
        await fetchChildUserDetails(childAccountId, onChildDetailsFetched);
      }
    } catch (e) {
      print('Error fetching accepted requests: $e');
    }
  }

  Future<void> fetchChildUserDetails(
      String childAccountId, Function onChildDetailsFetched) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('studentID', isEqualTo: childAccountId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        final userId = snapshot.docs.first.id;
        final email = userData['email'] as String? ?? 'No Email';
        onChildDetailsFetched(userId, email);
      } else {
        print('No user found with studentID $childAccountId');
      }
    } catch (e) {
      print('Error fetching child user details: $e');
    }
  }

  void listenToChildLocationUpdates(
      String userId, Function(Map<String, dynamic>) onLocationUpdated) {
    _firestore
        .collection('locations')
        .doc(userId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        final locationData = docSnapshot.data();
        if (locationData != null) {
          onLocationUpdated(locationData);
        }
      } else {
        print('No location found for user ID $userId');
      }
    });
  }

  Future<List<Map<String, dynamic>>> getUserLocationHistory(
      String userId, DateTime selectedDate) async {
    List<Map<String, dynamic>> locations = [];
    final historySnapshot = await _firestore
        .collection('location_history')
        .doc(userId)
        .collection('locations')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day)))
        .where('timestamp',
            isLessThan: Timestamp.fromDate(DateTime(
                    selectedDate.year, selectedDate.month, selectedDate.day)
                .add(const Duration(days: 1))))
        .orderBy('timestamp')
        .get();

    for (var doc in historySnapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      final timestamp = data['timestamp'] as Timestamp?;
      if (lat != null && lng != null && timestamp != null) {
        locations.add({
          'position': LatLng(lat, lng),
          'timestamp': timestamp.toDate(),
        });
      }
    }
    return locations;
  }
}
