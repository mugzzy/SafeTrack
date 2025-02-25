import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocalPushNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> handleGeofenceStatus(String eventId) async {
    FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .snapshots()
        .listen((eventSnapshot) async {
      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.data();
        if (eventData != null) {
          final List<String> studentIds =
              List<String>.from(eventData['studentIds'] ?? []);
          for (String studentId in studentIds) {
            final studentDoc = await FirebaseFirestore.instance
                .collection('locations')
                .doc(studentId)
                .get();

            if (studentDoc.exists) {
              final studentData = studentDoc.data();
              if (studentData != null) {
                final double latitude = studentData['latitude'];
                final double longitude = studentData['longitude'];
                final double geofenceCenterLat =
                    eventData['geofenceCenter'].latitude;
                final double geofenceCenterLng =
                    eventData['geofenceCenter'].longitude;
                final double geofenceRadius = eventData['geofenceRadius'];

                final double distance = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  geofenceCenterLat,
                  geofenceCenterLng,
                );

                if (distance > geofenceRadius) {
                  final String teacherId = eventData['teacherId'];
                  final teacherDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(teacherId)
                      .get();

                  if (teacherDoc.exists) {
                    final teacherData = teacherDoc.data();
                    if (teacherData != null) {
                      final String teacherName = teacherData['name'];
                      await showNotification(
                        title: 'Student Outside Geofence',
                        body: 'A student has moved outside the geofence area.',
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    });
  }
}
