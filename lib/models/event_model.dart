import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String eventName;
  final DateTime startTime;
  final DateTime endTime;
  final String teacherId;
  final List<String> studentIds;
  final GeoPoint geofenceCenter;
  final double geofenceRadius;
  final DateTime createdAt;

  EventModel({
    required this.eventId,
    required this.eventName,
    required this.startTime,
    required this.endTime,
    required this.teacherId,
    required this.studentIds,
    required this.geofenceCenter,
    required this.geofenceRadius,
    required this.createdAt,
  });

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final upcomingThreshold = now.add(Duration(hours: 24));
    return now.isBefore(startTime) && startTime.isBefore(upcomingThreshold);
  }

  factory EventModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: doc.id,
      eventName: data['eventName'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      teacherId: data['teacherId'],
      studentIds: List<String>.from(data['studentIds']),
      geofenceCenter: GeoPoint(
        data['geofence']['center'].latitude,
        data['geofence']['center'].longitude,
      ),
      geofenceRadius:
          (data['geofence']['radius'] as num).toDouble(), // Cast to double
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'startTime': startTime,
      'endTime': endTime,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'geofence': {
        'center': geofenceCenter,
        'radius': geofenceRadius,
      },
      'createdAt': createdAt,
    };
  }
}
