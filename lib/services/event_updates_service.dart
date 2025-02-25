// location_service.dart

import 'package:capstone_1/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class EventUpdatesService {
  final Map<String, String> _geofenceState = {};

  Future<void> checkStudentLocations({
    required EventModel event,
    required void Function(int outsideCount, int leftCount) updateCounts,
  }) async {
    if (!event.isOngoing) return;

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where(FieldPath.documentId, whereIn: event.studentIds)
          .get();

      final eventSummarySnapshot = await FirebaseFirestore.instance
          .collection('event_notifications')
          .doc(event.eventId)
          .collection('event_updates')
          .doc('event_summary')
          .get();

      Map<String, int> studentsLeaveCounts =
          eventSummarySnapshot.exists && eventSummarySnapshot.data() != null
              ? Map<String, int>.from(
                  eventSummarySnapshot.data()?['studentsLeaveCounts'] ?? {})
              : {};

      int outsideCount = 0;
      int leftCount = 0;
      Map<String, String> updatedStates = {};

      // Initialize geofence states if not set
      for (var doc in studentsSnapshot.docs) {
        final studentId = doc.id;
        if (!_geofenceState.containsKey(studentId)) {
          _geofenceState[studentId] = "unknown";
        }
      }

      for (var doc in studentsSnapshot.docs) {
        final studentId = doc.id;
        final locationData = doc.data();
        final latitude = locationData['latitude'];
        final longitude = locationData['longitude'];

        double distance = calculateDistance(
          event.geofenceCenter.latitude,
          event.geofenceCenter.longitude,
          latitude,
          longitude,
        );

        final isInside = distance <= event.geofenceRadius;
        String newState = isInside ? "inside" : "outside";

        if (_geofenceState[studentId] != newState) {
          _geofenceState[studentId] = newState;
          updatedStates[studentId] = newState;
        }

        if (newState == "outside") outsideCount++;
      }

      for (var entry in updatedStates.entries) {
        String studentId = entry.key;
        String newState = entry.value;
        String email = studentsSnapshot.docs
            .firstWhere((doc) => doc.id == studentId)
            .data()['email'];

        await saveUpdate(
          eventId: event.eventId,
          email: email,
          update: newState == "outside"
              ? 'outside the event.'
              : 'entered the event.',
          studentId: studentId,
          studentsLeaveCounts: studentsLeaveCounts,
        );

        if (newState == "outside") {
          leftCount++;
        }
      }

      await FirebaseFirestore.instance
          .collection('event_notifications')
          .doc(event.eventId)
          .collection('event_updates')
          .doc('event_summary')
          .set({
        'studentsLeaveCounts': studentsLeaveCounts,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      updateCounts(outsideCount, leftCount);
    } catch (e) {
      print('Error checking student locations: $e');
    }
  }

  Future<void> saveUpdate({
    required String eventId,
    required String email,
    required String update,
    required String studentId,
    required Map<String, int> studentsLeaveCounts,
  }) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('event_notifications')
          .doc(eventId)
          .collection('event_notifications')
          .where('email', isEqualTo: email)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var lastUpdate = querySnapshot.docs.first.data();
        if (lastUpdate['update'] == update) {
          print(
              "Same notification already exists for $email. Skipping update.");
          return;
        }
      }

      if (update == 'outside the event.') {
        studentsLeaveCounts[studentId] =
            (studentsLeaveCounts[studentId] ?? 0) + 1;
        print(
            "Leave count incremented for $studentId: ${studentsLeaveCounts[studentId]}");
      }

      await FirebaseFirestore.instance
          .collection('event_notifications')
          .doc(eventId)
          .collection('event_notifications')
          .add({
        'email': email,
        'update': update,
        'timestamp': Timestamp.now(),
      });

      print("Update saved for $email: $update");
    } catch (error) {
      print("Error saving update for $email: $error");
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}
