import 'package:capstone_1/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class GeofenceHandler {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if the student is part of the event
  Future<bool> _isStudentPartOfEvent(String eventId, String studentId) async {
    try {
      DocumentSnapshot eventSnapshot =
          await _db.collection('events').doc(eventId).get();
      if (eventSnapshot.exists) {
        var data = eventSnapshot.data() as Map<String, dynamic>;
        List<dynamic> studentIds = data['studentIds'] ?? [];
        return studentIds.contains(studentId);
      }
    } catch (e) {
      print('Error checking student participation: $e');
    }
    return false;
  }

  // Log attendance when a student enters a geofence
  Future<void> logAttendance({
    required String studentId,
    required String eventName,
    required String teacherId,
    required String geoStatus,
    required bool isInside,
    required String phoneIpAddress,
    required String deviceId,
    required String osVersion,
    required String deviceModel,
  }) async {
    try {
      String today =
          DateTime.now().toIso8601String().split('T').first; // Today's date
      String time = DateFormat.jm()
          .format(DateTime.now()); // Current time in 'hh:mm a' format

      DocumentReference attendanceRef = _db
          .collection('attendance')
          .doc(today)
          .collection(eventName)
          .doc(studentId);

      DocumentSnapshot snapshot = await attendanceRef.get();

      // If student enters, record timeIn; if exits, record timeOut
      if (isInside) {
        if (!snapshot.exists) {
          await attendanceRef.set({
            'eventName': eventName,
            'teacherId': teacherId,
            'studentId': studentId,
            'timeIn': time,
            'timeOut': time,
            'timestamp': FieldValue.serverTimestamp(),
            'geoStatus': geoStatus,
            'PhoneIPAddress': phoneIpAddress,
            'deviceId': deviceId,
            'osVersion': osVersion,
            'deviceModel': deviceModel
          });
        }
      } else {
        if (snapshot.exists) {
          await attendanceRef.update({
            'timeOut': time,
            'geoStatus': geoStatus,
            'PhoneIPAddress': phoneIpAddress,
          });
        }
      }
    } catch (e) {
      print('Error logging attendance: $e');
    }
  }

  // Fetch geofence markers
  Future<List<Marker>> fetchMarkers(String studentId) async {
    List<Marker> markers = [];
    List<Circle> _ = []; // Placeholder for circles
    await _processEvent(studentId: studentId, markers: markers, circles: _);
    print('Total markers fetched: ${markers.length}');
    return markers;
  }

  // Fetch geofence circles
  Future<List<Circle>> fetchCircles(String studentId) async {
    List<Marker> _ = []; // Placeholder for markers
    List<Circle> circles = [];
    await _processEvent(studentId: studentId, markers: _, circles: circles);
    print('Total circles fetched: ${circles.length}');
    return circles;
  }

  // Fetch event attendance records
  Future<List<Map<String, dynamic>>> fetchEventAttendance(
      String eventName, String date) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('attendance')
          .doc(date)
          .collection(eventName)
          .get();

      List<Map<String, dynamic>> attendanceRecords = [];
      for (var doc in snapshot.docs) {
        attendanceRecords.add(doc.data() as Map<String, dynamic>);
      }
      return attendanceRecords;
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  // Helper method to process events for markers and circles
  Future<void> _processEvent({
    required String studentId,
    required List<Marker> markers,
    required List<Circle> circles,
  }) async {
    try {
      QuerySnapshot snapshot = await _db.collection('events').get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        var eventModel = EventModel.fromDocument(doc);

        // Check if the student is part of the event and the event is ongoing/upcoming
        if (eventModel.studentIds.contains(studentId) &&
            (eventModel.isOngoing || eventModel.isUpcoming)) {
          // Add marker
          markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(eventModel.geofenceCenter.latitude,
                eventModel.geofenceCenter.longitude),
            infoWindow: InfoWindow(
              title: eventModel.eventName,
              snippet: 'Radius: ${eventModel.geofenceRadius} meters',
            ),
          ));

          // Add circle
          if (data.containsKey('geofence')) {
            var geofenceData = data['geofence'];
            GeoPoint center = geofenceData['center'];
            double radius =
                (geofenceData['radius'] as num).toDouble(); // Convert to double

            circles.add(Circle(
              circleId: CircleId(doc.id),
              center: LatLng(center.latitude, center.longitude),
              radius: radius,
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ));
          }
        }
      }
    } catch (e) {
      print('Error processing events: $e');
    }
  }
}
