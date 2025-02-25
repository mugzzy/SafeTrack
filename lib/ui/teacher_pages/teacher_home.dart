import 'dart:async';

import 'package:capstone_1/services/event_updates_service.dart';
import 'package:capstone_1/ui/teacher_pages/event_transaction/event_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/event_model.dart';
import '../../services/kalmanfilter.dart';
import '../../services/location_service.dart';

class TeacherHome extends StatefulWidget {
  final String? eventId;

  const TeacherHome({
    Key? key,
    this.eventId,
  }) : super(key: key);

  @override
  _TeacherHomeState createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  bool _hasNotifications = false;
  final EventUpdatesService _eventUpdatesService = EventUpdatesService();
  LatLng? _currentPosition;
  StreamSubscription<DocumentSnapshot>? _positionStreamSubscription;
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  int studentsOutsideCount = 0;
  int _outsideCount = 0;
  int _leftCount = 0;
  List<Map<String, dynamic>> studentsOutsideDetails = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int? _lastUpdate;
  bool _loading = true;
  Map<String, LatLng> _studentLocations = {};
  Map<String, String> _studentEmails = {};
  final Map<String, String> _studentStatus = {}; // Added from `code1`
  final KalmanFilter _locationPredictionService = KalmanFilter();

  EventModel? _event;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadEvent();
    fetchStudentsOutside();
    _listenForNotifications();
    _checkLocations();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkLocations() async {
    if (_event == null) {
      print("Event data is not loaded yet.");
      return;
    }

    await _eventUpdatesService.checkStudentLocations(
      event: _event!,
      updateCounts: (outsideCount, leftCount) {
        setState(() {
          _outsideCount = outsideCount;
          _leftCount = leftCount;
        });
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _trackLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  void _trackLocation() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _locationService.getPositionStream().listen((Position position) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_lastUpdate == null || now - _lastUpdate! > 3000) {
          _lastUpdate = now;
          _locationService.updateLocation(position);
        }
      });
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    if (_userId.isNotEmpty) {
      _positionStreamSubscription = _firestore
          .collection('locations')
          .doc(_userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data();
          if (data != null) {
            var latitude = data['latitude'] as double?;
            var longitude = data['longitude'] as double?;

            if (latitude != null && longitude != null) {
              LatLng newPosition = LatLng(latitude, longitude);

              if (_currentPosition == null || _currentPosition != newPosition) {
                if (mounted) {
                  setState(() {
                    _currentPosition = newPosition;
                  });
                }

                if (_mapController != null) {
                  _mapController!.animateCamera(
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
        }
      });
    }
  }

  void _loadEvent() {
    if (widget.eventId != null) {
      _fetchEventDetailsById(widget.eventId!);
    } else {
      _fetchLatestEvent();
    }
  }

  Future<void> _fetchEventDetailsById(String eventId) async {
    try {
      DocumentSnapshot eventDoc =
          await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        if (mounted) {
          setState(() {
            _event = EventModel.fromDocument(eventDoc);
            _loading = false;
            _moveCameraToEventCenter();
          });
        }
        _listenToLocationUpdates();
        _listenToPredictedStatusUpdates();
      } else {
        _fetchLatestEvent();
      }
    } catch (e) {
      _fetchLatestEvent();
    }
  }

  Future<void> _fetchLatestEvent() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('teacherId', isEqualTo: userId)
          .get();

      List<EventModel> events =
          snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          if (events.isNotEmpty) {
            _event = events.first;
          } else {
            _event = null;
          }
          _loading = false;
        });
      }

      if (_event != null) {
        _listenToLocationUpdates();
        _listenToPredictedStatusUpdates();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _event = null;
          _loading = false;
        });
      }
    }
  }

  void _listenForNotifications() {
    if (_userId.isEmpty) {
      print("Teacher ID is empty. Cannot listen for notifications.");
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    firestore
        .collection(
            'student_notifications') // Ensure this matches Firestore collection
        .where('teacher.teacherId', isEqualTo: _userId)
        .where('teacher.status', isEqualTo: 'unseen')
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> notifications = querySnapshot.docs
            .map((doc) =>
                {'id': doc.id, 'data': doc.data() as Map<String, dynamic>})
            .toList();

        // Show Dialog with Notifications
        _showNotificationDialog(notifications);
      }
    });
  }

  void _showNotificationDialog(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Emergency Notifications"),
          content: SizedBox(
            height: 200,
            width: 300,
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index]['data'];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification['message'] ?? "No message",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("From: ${notification['userEmail'] ?? 'Unknown'}"),
                    Text("Time: ${notification['timestamp'] ?? 'Unknown'}"),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                FirebaseFirestore firestore = FirebaseFirestore.instance;
                for (var notif in notifications) {
                  await firestore
                      .collection('student_notifications')
                      .doc(notif['id'])
                      .update({'teacher.status': 'seen'});
                }

                // Extract sender ID and move camera to their location
                var firstNotification = notifications.first['data'];
                String? senderId = firstNotification[
                    'userId']; // Ensure the key matches Firestore field

                if (senderId != null &&
                    _studentLocations.containsKey(senderId)) {
                  LatLng senderLocation = _studentLocations[senderId]!;
                  _moveCameraToLocation(senderLocation);
                }

                Navigator.pop(context); // Close dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _moveCameraToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 17.0, // Zoom in to focus on sender's location
        ),
      ),
    );
  }

  Future<void> fetchStudentsOutside() async {
    try {
      // Ensure _event is loaded before fetching student data
      if (_event == null) {
        await _fetchLatestEvent();
      }

      // Check again if _event is still null after fetching
      if (_event == null) {
        throw Exception(
            "Event ID is null even after fetching the latest event.");
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('event_notifications')
          .doc(_event!.eventId)
          .collection('event_updates')
          .doc('event_summary')
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;

        setState(() {
          studentsOutsideCount = data['outsideCount'] ?? 0;

          if (data['studentsLeaveCounts'] is Map<String, dynamic>) {
            studentsOutsideDetails =
                (data['studentsLeaveCounts'] as Map<String, dynamic>)
                    .entries
                    .map((entry) => {
                          'studentId': entry.key,
                          'leaveCount': entry.value ?? 0,
                        })
                    .toList();
          } else {
            studentsOutsideDetails = [];
          }
        });
      } else {
        setState(() {
          studentsOutsideCount = 0;
          studentsOutsideDetails = [];
        });

        print("No data found, defaulting to empty.");
      }
    } catch (e) {
      print("Error fetching student data: $e");
    }
  }

  void showStudentDetailsDialog(
      BuildContext context, List<Map<String, dynamic>> studentsOutsideDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                "Students Who Left",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: studentsOutsideDetails.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: studentsOutsideDetails.map((student) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Icon(Icons.person,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(
                            "  ${student['studentId']}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Leave Count: ${student['leaveCount']}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.blueAccent, size: 50),
                      const SizedBox(height: 10),
                      const Text(
                        "No students have left the event.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Close", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _listenToLocationUpdates() async {
    if (_event == null || (!(_event!.isOngoing || _event!.isUpcoming))) {
      if (mounted) {
        setState(() {
          _studentLocations.clear();
          _studentEmails.clear();
        });
      }
      return;
    }

    _firestore.collection('locations').snapshots().listen((snapshot) async {
      for (var doc in snapshot.docs) {
        String studentId = doc.id;

        if (_event!.studentIds.contains(studentId)) {
          double latitude = doc['latitude'];
          double longitude = doc['longitude'];
          String email = doc['email'];
          bool isPredicted = doc.data().containsKey('isPredicted')
              ? doc['isPredicted']
              : false;
          LatLng location = LatLng(latitude, longitude);

          if (isPredicted) {
            Map<String, dynamic>? latestPrediction =
                await getLatestPrediction(studentId);
            if (latestPrediction != null) {
              double predictedLatitude = latestPrediction['latitude'];
              double predictedLongitude = latestPrediction['longitude'];
              location = LatLng(predictedLatitude, predictedLongitude);
            }
          }

          double distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            _event!.geofenceCenter.latitude,
            _event!.geofenceCenter.longitude,
          );

          String geofenceStatus =
              distance <= _event!.geofenceRadius ? 'Inside' : 'Outside';

          String onlineStatus;
          if (doc.data().containsKey('lastOnline')) {
            DateTime lastOnline = doc['lastOnline'].toDate();
            Duration offlineDuration = DateTime.now().difference(lastOnline);

            onlineStatus =
                offlineDuration.inMinutes <= 1 ? 'Online' : 'Offline';
            if (offlineDuration.inMinutes >= 90) {
              await FirebaseFirestore.instance
                  .collection('locations')
                  .doc(studentId)
                  .set({'isPredicted': false}, SetOptions(merge: true));
            }
          } else {
            onlineStatus = 'Offline';
          }

          if (_studentStatus[studentId] == 'Offline' &&
              onlineStatus == 'Online') {
            _showSnackbar('Student $email is back online');
            FirebaseFirestore.instance
                .collection('locations')
                .doc(studentId)
                .set({'isPredicted': false}, SetOptions(merge: true));
          } else if (_studentStatus[studentId] == 'Online' &&
              onlineStatus == 'Offline') {
            _showSnackbar('Student $email has gone offline');

            Timer(Duration(minutes: 1), () {
              if (_studentStatus[studentId] == 'Offline') {
                FirebaseFirestore.instance
                    .collection('locations')
                    .doc(studentId)
                    .set({'isPredicted': true}, SetOptions(merge: true));
              }
            });
          }

          _studentStatus[studentId] = onlineStatus;

          if (mounted) {
            setState(() {
              _studentLocations[studentId] = location;
              _studentEmails[studentId] =
                  '$email ($geofenceStatus, $onlineStatus, isPredicted=$isPredicted; )';
            });
          }
        }
      }
    });
  }

  Future<void> _listenToPredictedStatusUpdates() async {
    if (_event == null || _event!.studentIds.isEmpty) {
      return; // No event or students, nothing to process
    }

    // Listen to changes in the `locations` collection
    _firestore.collection('locations').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        String studentId = change.doc.id;

        // Check if the student is part of the current event
        if (_event!.studentIds.contains(studentId)) {
          if (change.type == DocumentChangeType.modified) {
            // Check if the `isPredicted` field has changed
            bool? newIsPredicted = change.doc.data()?['isPredicted'];
            if (newIsPredicted != null) {
              _handlePredictedStatusChange(studentId, newIsPredicted);
            }
          }
        }
      }
    });
  }

  Future<void> _handlePredictedStatusChange(
      String studentId, bool isPredicted) async {
    // Log the change (or trigger other actions)
    if (isPredicted) {
      await _locationPredictionService.predictAndStoreLocation(studentId);
      //_showSnackbar('Student $studentId is now predicted.');
      // Add further actions for when `isPredicted` is true
    } else {
      await _locationPredictionService.stopPredictAndStoreLocation(studentId);

      // Add further actions for when `isPredicted` is false
    }

    // Update the UI if necessary
    if (mounted) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>?> getLatestPrediction(String userId) async {
    try {
      // Reference to the user's predictions sub-collection
      CollectionReference predictionsRef = FirebaseFirestore.instance
          .collection('predicted_location')
          .doc(userId)
          .collection('predictions');

      // Query the latest prediction based on the highest minute value
      QuerySnapshot latestPredictionSnapshot = await predictionsRef
          .orderBy('minute', descending: true)
          .limit(1)
          .get();

      if (latestPredictionSnapshot.docs.isNotEmpty) {
        // Fetch the latest prediction document
        DocumentSnapshot latestDoc = latestPredictionSnapshot.docs.first;

        // Return the data as a map
        print('Latest prediction for userId $userId: ${latestDoc.data()}');
        return latestDoc.data() as Map<String, dynamic>;
      } else {
        print('No predictions found for userId: $userId');
        return null;
      }
    } catch (e) {
      print('Error fetching latest prediction for userId $userId: $e');
      return null;
    }
  }

  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _moveCameraToEventCenter() {
    if (_event != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            _event!.geofenceCenter.latitude,
            _event!.geofenceCenter.longitude,
          ),
          18,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentPosition == null && _event != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _event!.geofenceCenter.latitude,
              _event!.geofenceCenter.longitude,
            ),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Loading Event...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Event Geofence'),
        ),
        body: const Center(
          child: Text('No events found for this teacher.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Event Geofence - ${_event!.eventName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _loading = true; // Show loading state
              });
              await Future.delayed(const Duration(seconds: 1));
              await _listenToLocationUpdates();
              setState(() {
                _loading = false; // Hide loading state
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _event!.geofenceCenter.latitude,
                _event!.geofenceCenter.longitude,
              ),
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('eventLocation'),
                position: LatLng(
                  _event!.geofenceCenter.latitude,
                  _event!.geofenceCenter.longitude,
                ),
                infoWindow: InfoWindow(title: _event!.eventName),
              ),
              ..._studentLocations.entries.map((entry) {
                String studentId = entry.key;
                String studentInfo = _studentEmails[studentId] ?? 'No email';
                bool isPredicted = studentInfo.contains('isPredicted=true');

                // Parse geofence and online status
                String geofenceStatus =
                    studentInfo.contains('Inside') ? 'Inside' : 'Outside';
                String onlineStatus =
                    studentInfo.contains('Online') ? 'Online' : 'Offline';

                // Determine marker icon color
                BitmapDescriptor icon;
                if (geofenceStatus == 'Inside' && onlineStatus == 'Online') {
                  icon = BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen);
                  // Green for inside and online
                } else if (geofenceStatus == 'Inside' &&
                    onlineStatus == 'Offline') {
                  icon = BitmapDescriptor.defaultMarkerWithHue(210);
                  // Replace gray (210) with custom marker if available
                } else if (geofenceStatus == 'Outside' &&
                    onlineStatus == 'Online') {
                  icon = BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueYellow);
                  // Yellow for outside and online
                } else if (geofenceStatus == 'Outside' &&
                    onlineStatus == 'Offline') {
                  icon = BitmapDescriptor.defaultMarkerWithHue(210);
                  // Replace gray (210) with custom marker if available
                } else if (isPredicted) {
                  icon = BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueCyan);
                  // Cyan for predicted
                } else {
                  icon = BitmapDescriptor.defaultMarker;
                  // Default color for undefined states
                }

                return Marker(
                  markerId: MarkerId(studentId),
                  position: entry.value,
                  infoWindow: InfoWindow(
                    title: studentInfo.split(',')[0],
                    snippet: studentInfo.split(',').length > 1
                        ? studentInfo.split(',')[1]
                        : '',
                  ),
                  icon: icon, // Use dynamically determined icon
                );
              }).toSet(),
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentPosition!,
                  infoWindow: const InfoWindow(title: 'Your Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue, // Set marker color to blue
                  ),
                ),
            },
            circles: {
              Circle(
                circleId: const CircleId('geofence'),
                center: LatLng(
                  _event!.geofenceCenter.latitude,
                  _event!.geofenceCenter.longitude,
                ),
                radius: _event!.geofenceRadius,
                fillColor: Colors.blue.withOpacity(0.2),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            },
            onMapCreated: _onMapCreated,
          ),
          if (_loading)
            Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                await fetchStudentsOutside(); // Ensure data is fetched before opening the dialog
                Navigator.pop(context); // Close loading dialog

                print("Fetched student details: $studentsOutsideDetails");

                showStudentDetailsDialog(context, studentsOutsideDetails);
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Students Outside: ${_studentEmails.values.where((s) => s.contains("Outside")).length}',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent, // Background color
                    shape: BoxShape.circle, // Make the container circular
                  ),
                  child: IconButton(
                    iconSize: 100, // Increase the size of the icon button
                    icon: Icon(
                      _hasNotifications
                          ? Icons.notifications
                          : Icons.notifications_none,
                      color: Colors.white, // Change icon color to white
                      size: 30, // Adjust the size of the icon itself
                    ),
                    onPressed: () {
                      if (_event != null) {
                        showDialog(
                          context: context,
                          builder: (context) => EventUpdates(
                            event: _event!, // Pass the full EventModel instance
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Event details are not available.'),
                          ),
                        );
                      }
                    },
                    tooltip: 'Event Updates',
                  ),
                ),
                if (_hasNotifications)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4), // Increase padding
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(8), // Increase border radius
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16, // Increase min width
                        minHeight: 16, // Increase min height
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12, // Increase font size
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
