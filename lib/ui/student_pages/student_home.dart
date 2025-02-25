import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:capstone_1/services/geofence_handler.dart'; // Import GeofenceHandler
import 'package:capstone_1/ui/student_pages/invited_geo_display.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'student_sendnotif.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  LatLng? _currentPosition;
  Map<String, Map<String, dynamic>> _teacherLocations =
      {}; // Map to store teacher locations with event details
  List<Marker> _geofenceMarkers = []; // List to store geofence markers
  List<Circle> _geofenceCircles = []; // List to store geofence circles
  StreamSubscription<DocumentSnapshot>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _teacherPositionStreamSubscription;
  GoogleMapController? _mapController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final LatLng _defaultPosition = const LatLng(7.0736, 125.6110);

  String? _currentGeofenceStatus; // New variable for geofence status

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startTeacherLocationUpdates();
    _loadGeofences(); // Fetch the geofences (markers and circles) from Firestore
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _teacherPositionStreamSubscription?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _isInsideGeofence(LatLng userPosition) {
    for (Circle geofence in _geofenceCircles) {
      double distance = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );

      if (distance <= geofence.radius) {
        // Find the associated event name for the geofence
        String? eventName;
        for (Marker marker in _geofenceMarkers) {
          if (marker.position == geofence.center) {
            eventName = marker.infoWindow.title?.replaceFirst('Geofence: ', '');
            break;
          }
        }
        return {
          'inside': true,
          'eventName': eventName ?? 'Unknown Event',
        }; // Inside this geofence
      }
    }
    return {
      'inside': false,
      'eventName': null,
    }; // Outside all geofences
  }

  void _checkGeofenceStatus(LatLng newPosition) {
    var geofenceStatus = _isInsideGeofence(newPosition);

    // Determine new geofence status
    String newStatus = geofenceStatus?['inside'] == true ? 'inside' : 'outside';

    // Check if status has changed
    if (_currentGeofenceStatus != newStatus) {
      setState(() {
        _currentGeofenceStatus = newStatus;
      });

      // Show dialog with clear status
      _showGeofenceDialog(newStatus, geofenceStatus?['eventName']);
    }
  }

  void _showGeofenceDialog(String status, String? eventName) {
    String message = (status == 'inside')
        ? 'You are currently inside the event area.\nEvent: ${eventName ?? 'Unknown'}'
        : 'You are currently outside the event area.\nPlease come back immediately!';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Modern rounded design
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Adjust height based on content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!, // Divider for sections
                      width: 1.0,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Geofence Status',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              // Content Section
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  height: 1.5, // Improved line spacing for better readability
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 24.0),

              // Action Button Section
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // accentBlue color
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded button
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 12.0,
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth's radius in meters
    double dLat = (lat2 - lat1) * (3.14159265359 / 180);
    double dLon = (lon2 - lon1) * (3.14159265359 / 180);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * (3.14159265359 / 180)) *
            cos(lat2 * (3.14159265359 / 180)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

  void _startLocationUpdates() {
    if (_userId.isNotEmpty) {
      final NetworkInfo networkInfo = NetworkInfo();
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? ipAddress;
      String deviceId = 'Unknown Device ID';
      String osVersion = 'Unknown OS Version';
      String deviceModel = 'Unknown Device Model';

      _positionStreamSubscription = _db
          .collection('locations')
          .doc(_userId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists) {
          var data = snapshot.data();
          if (data != null) {
            var latitude = data['latitude'] as double?;
            var longitude = data['longitude'] as double?;

            if (latitude != null && longitude != null) {
              LatLng newPosition = LatLng(latitude, longitude);
              _checkGeofenceStatus(newPosition);

              // Fetch IP address
              ipAddress =
                  await networkInfo.getWifiIP(); // Get the Wi-Fi IP address
              ipAddress ??=
                  await networkInfo.getWifiIPv6(); // Fallback for IPv6
              ipAddress ??= 'Unknown IP'; // Fallback if no IP is available

              // Fetch device information
              if (Platform.isAndroid) {
                var androidInfo = await deviceInfo.androidInfo;
                deviceId = androidInfo.id; // Android ID
                osVersion = 'Android ${androidInfo.version.release}';
                deviceModel = androidInfo.model; // Android device model
              } else if (Platform.isIOS) {
                var iosInfo = await deviceInfo.iosInfo;
                deviceId = iosInfo.identifierForVendor ?? 'Unknown ID';
                osVersion = 'iOS ${iosInfo.systemVersion}';
                deviceModel = iosInfo.model; // iOS device model
              }

              // Check if inside geofence and get event name
              var geofenceStatus = _isInsideGeofence(newPosition);

              // Call logAttendance if inside a geofence
              if (geofenceStatus != null && geofenceStatus['inside'] == true) {
                String eventName = geofenceStatus['eventName'];
                GeofenceHandler geofenceHandler = GeofenceHandler();

                await geofenceHandler.logAttendance(
                  studentId: _userId,
                  eventName: eventName,
                  teacherId:
                      "teacher_id_placeholder", // Replace with actual teacher ID
                  geoStatus: "Inside", // Or any relevant geo-status
                  isInside: true,
                  phoneIpAddress:
                      ipAddress ?? 'Unknown IP', // Pass the IP address
                  deviceId: deviceId, // Pass the Device ID
                  osVersion: osVersion, // Pass the OS Version
                  deviceModel: deviceModel, // Pass the device model
                );
              }

              if (_currentPosition == null || _currentPosition != newPosition) {
                setState(() {
                  _currentPosition = newPosition;

                  // Update marker with dynamic label
                  // Update marker with dynamic label
                  _geofenceMarkers.removeWhere(
                      (marker) => marker.markerId.value == 'currentLocation');
                  _geofenceMarkers.add(
                    Marker(
                      markerId: const MarkerId('currentLocation'),
                      position: _currentPosition!,
                      infoWindow: InfoWindow(
                        title:
                            'Your Location: ${geofenceStatus != null && geofenceStatus['inside'] == true ? 'Inside' : 'Outside'}',
                        snippet: geofenceStatus != null &&
                                geofenceStatus['inside'] == true
                            ? 'Event: ${geofenceStatus['eventName'] ?? 'Unknown'}'
                            : null,
                      ),
                    ),
                  );
                });

                // Animate camera to new position
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: newPosition,
                      zoom: 16.0,
                    ),
                  ),
                );
              }
            }
          }
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOngoingEvents() async {
    final now = DateTime.now();
    final events = await _db.collection('events').get();

    List<Map<String, dynamic>> ongoingEvents = [];
    for (var doc in events.docs) {
      var startTime = (doc['startTime'] as Timestamp).toDate();
      var endTime = (doc['endTime'] as Timestamp).toDate();
      List<dynamic> studentIds = doc['studentIds'];
      String teacherId = doc['teacherId'] ?? '';

      if (startTime.isBefore(now) &&
          endTime.isAfter(now) &&
          studentIds.contains(_userId)) {
        ongoingEvents.add({
          'eventName': doc['eventName'] as String,
          'teacherId': teacherId,
        });
      }
    }

    return ongoingEvents;
  }

  Future<void> _startTeacherLocationUpdates() async {
    var ongoingEvents = await _fetchOngoingEvents();
    if (ongoingEvents.isNotEmpty) {
      List<String> teacherIds =
          ongoingEvents.map((e) => e['teacherId'] as String).toList();

      _teacherPositionStreamSubscription = _db
          .collection('locations')
          .where(FieldPath.documentId, whereIn: teacherIds)
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docs) {
          var data = doc.data();
          double latitude = data['latitude'];
          double longitude = data['longitude'];
          String teacherId = doc.id;

          // Find the corresponding event for this teacher
          var event =
              ongoingEvents.firstWhere((e) => e['teacherId'] == teacherId);
          String eventName = event['eventName'];

          setState(() {
            _teacherLocations[teacherId] = {
              'position': LatLng(latitude, longitude),
              'eventName': eventName,
            };
          });
        }
      });
    }
  }

  // Load geofences markers and circles
  Future<void> _loadGeofences() async {
    GeofenceHandler geofenceHandler = GeofenceHandler();

    // Fetch the geofence markers and circles
    List<Marker> markers = await geofenceHandler.fetchMarkers(_userId);
    List<Circle> circles = await geofenceHandler.fetchCircles(_userId);

    setState(() {
      _geofenceMarkers = markers;
      _geofenceCircles = circles;
    });
    print('Markers loaded: ${_geofenceMarkers.length}');
    print('Circles loaded: ${_geofenceCircles.length}');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition == null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _defaultPosition,
            zoom: 12.0,
          ),
        ),
      );
    }
  }

  void _openEmergencyNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentSendnotif()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Student Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu), // Hamburger icon
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                builder: (context) => const InvitedGeoDisplay(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? _defaultPosition,
              zoom: 12.0,
            ),
            markers: {
              // Current location marker (if available)
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentPosition!,
                  infoWindow: InfoWindow(
                    title:
                        'Your Location: ${_isInsideGeofence(_currentPosition!)?['inside'] == true ? 'Inside' : 'Outside'}',
                    snippet: _isInsideGeofence(_currentPosition!)?['inside'] ==
                            true
                        ? 'Event: ${_isInsideGeofence(_currentPosition!)?['eventName'] ?? 'Unknown'}'
                        : null,
                  ),
                ),

              // Teacher locations
              ..._teacherLocations.entries.map((entry) {
                final teacherId = entry.key;
                final position = entry.value['position'] as LatLng;
                final eventName = entry.value['eventName'] as String;

                return Marker(
                  markerId: MarkerId(teacherId),
                  position: position,
                  infoWindow: InfoWindow(
                    title: 'Teacher\'s Location',
                    snippet: 'Event: $eventName',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                );
              }),

              // Geofence markers (from the GeofenceHandler)
              ..._geofenceMarkers,
            },
            // Geofence circles (from the GeofenceHandler)
            circles: Set.from(_geofenceCircles),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_currentPosition == null)
            const Center(
              child: Text(
                'Fetching your location...',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _openEmergencyNotification,
        backgroundColor: Colors.blue,
        tooltip: 'Emergency Notification',
        child: const Icon(Icons.shield),
      ),
    );
  }
}
