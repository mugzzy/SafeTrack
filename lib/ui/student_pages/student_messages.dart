import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/location_service.dart';

class StudentMessagesPage extends StatefulWidget {
  const StudentMessagesPage({super.key});

  @override
  _StudentMessagesPageState createState() => _StudentMessagesPageState();
}

class _StudentMessagesPageState extends State<StudentMessagesPage> {
  final LocationService _locationService = LocationService();
  int? _lastUpdate;
  String? _studentID;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchStudentID();
    _startLocationHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _trackLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission denied'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
    }
  }

  Future<void> _fetchStudentID() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userDoc.exists) {
          setState(() {
            _studentID = userDoc.data()?['studentID'];
          });
          if (_studentID == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student ID not found in user document'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User document does not exist'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch student ID: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _startLocationHistory() {
    _timer = Timer.periodic(const Duration(minutes: 2), (Timer timer) async {
      await _locationHistory();
    });
  }

  Future<void> _locationHistory() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        };
        await FirebaseFirestore.instance
            .collection('location_history')
            .doc(currentUser.uid)
            .collection('locations')
            .add(locationData);
        print('Location stored: $locationData');
      } catch (e) {
        print('Failed to store location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Location Sharing Requests'),
        centerTitle: true,
      ),
      body: _studentID != null
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('studentID', isEqualTo: _studentID)
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No requests available.'));
                }

                final requests = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request =
                        requests[index].data() as Map<String, dynamic>;
                    final requestId = requests[index].id;

                    return RequestCard(
                      request: request,
                      onAccept: () {
                        _handleRequest(context, requestId, 'Accepted');
                      },
                      onDecline: () {
                        _handleRequest(context, requestId, 'Declined');
                      },
                    );
                  },
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  void _handleRequest(
      BuildContext context, String requestId, String status) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm $status'),
          content: Text('Are you sure you want to $status this request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .update({'status': status});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update request: $e')),
        );
      }
    }
  }
}

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const RequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final parentEmail = request['parentemail'] ?? 'N/A';
    final timestamp =
        (request['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final elapsedTime = DateTime.now().difference(timestamp);

    String formatElapsedTime(Duration duration) {
      if (duration.inMinutes < 60) {
        return '${duration.inMinutes} minutes ago';
      } else if (duration.inHours < 24) {
        return '${duration.inHours} hours ago';
      } else {
        return '${duration.inDays} days ago';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                formatElapsedTime(elapsedTime),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This person wants to know your location.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
