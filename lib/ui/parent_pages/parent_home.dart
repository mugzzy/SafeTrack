import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../services/location_history_service.dart';
import 'location_history/user_details_modal.dart';
import 'location_history/user_list.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  _ParentHomePageState createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  DateTime? _selectedDate;
  LatLng? _currentUserLocation;

  final LocationHistoryService _locationHistoryService =
      LocationHistoryService();

  @override
  void initState() {
    super.initState();
    _initializeCurrentUserLocation();
    _refreshMap();
  }

  Future<void> _initializeCurrentUserLocation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final locationSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(userId)
          .get();

      if (locationSnapshot.exists) {
        final locationData = locationSnapshot.data();
        if (locationData != null) {
          final latitude = locationData['latitude'] as double?;
          final longitude = locationData['longitude'] as double?;

          if (latitude != null && longitude != null) {
            setState(() {
              _currentUserLocation = LatLng(latitude, longitude);
            });
          }
        }
      }
    }
  }

  void _refreshMap() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      _selectedDate = null;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _locationHistoryService.fetchAcceptedRequests(userId, _fetchChildDetails);
      _addCurrentUserLocation(); // Add parent marker
    }
  }

  void _fetchChildDetails(String userId, String email) {
    _locationHistoryService.listenToChildLocationUpdates(userId,
        (locationData) {
      _updateMapLocation(userId, email, locationData);
    });
  }

  void _updateMapLocation(
      String userId, String email, Map<String, dynamic> locationData) {
    final latitude = locationData['latitude'] as double?;
    final longitude = locationData['longitude'] as double?;
    if (latitude != null && longitude != null) {
      final markerId = MarkerId(userId);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: email,
          snippet: 'Location shared',
        ),
        onTap: () => _showUserDetailsModal(userId, email),
      );

      setState(() {
        _markers.removeWhere((marker) => marker.markerId == markerId);
        _markers.add(marker);
      });
    }
  }

  void _showUserDetailsModal(String userId, String email) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return UserDetailsModal(
          userId: userId,
          email: email,
          onViewLocationHistory: (selectedUserId) {
            _pickDateAndShowUserLocationHistory(selectedUserId);
          },
        );
      },
    );
  }

  void _pickDateAndShowUserLocationHistory(String userId) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _showUserLocationHistory(userId, pickedDate);
    }
  }

  void _showUserLocationHistory(String userId, DateTime selectedDate) async {
    final locations = await _locationHistoryService.getUserLocationHistory(
        userId, selectedDate);
    _drawPolyline(userId, locations);
    _addHistoryMarkers(userId, locations);
    _zoomToUserLocationHistory(locations);
  }

  void _drawPolyline(String userId, List<Map<String, dynamic>> locations) {
    final polylineId = PolylineId(userId);
    final polyline = Polyline(
      polylineId: polylineId,
      color: Colors.blue,
      width: 5,
      points:
          locations.map((location) => location['position'] as LatLng).toList(),
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap() async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blueAccent;
    const double radius = 5.0; // Adjust size as needed

    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    final img = await pictureRecorder
        .endRecording()
        .toImage(radius.toInt() * 2, radius.toInt() * 2);
    final ByteData? byteData =
        await img.toByteData(format: ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  Future<void> _addHistoryMarkers(
      String userId, List<Map<String, dynamic>> locations) async {
    final BitmapDescriptor dotIcon = await createCustomMarkerBitmap();

    setState(() {
      _markers.clear(); // Clear any existing markers before adding the new ones

      if (locations.isEmpty) return;

      // Add the first marker
      final firstLocation = locations.first;
      final firstPosition = firstLocation['position'] as LatLng;
      final firstTimestamp = firstLocation['timestamp'] as DateTime;
      final firstMarkerId = MarkerId('$userId-first');
      final firstMarker = Marker(
        markerId: firstMarkerId,
        position: firstPosition,
        infoWindow: InfoWindow(
          title: 'First Location',
          snippet:
              'Timestamp: ${DateFormat('MM/dd/yyyy hh:mm a').format(firstTimestamp)}',
        ),
      );
      _markers.add(firstMarker);
      // Add the last marker (if the first and last are different)
      final lastLocation = locations.last;
      final lastPosition = lastLocation['position'] as LatLng;
      final lastTimestamp = lastLocation['timestamp'] as DateTime;
      final lastMarkerId = MarkerId('$userId-last');
      final lastMarker = Marker(
        markerId: lastMarkerId,
        position: lastPosition,
        infoWindow: InfoWindow(
          title: 'Last Location',
          snippet:
              'Timestamp: ${DateFormat('MM/dd/yyyy hh:mm a').format(lastTimestamp)}',
        ),
      );
      _markers.add(lastMarker);

      // Add intermediate markers as dots
      if (locations.length > 2) {
        for (int i = 1; i < locations.length - 1; i++) {
          final intermediateLocation = locations[i];
          final intermediatePosition =
              intermediateLocation['position'] as LatLng;
          final intermediateTimestamp =
              intermediateLocation['timestamp'] as DateTime;
          final intermediateMarkerId = MarkerId('$userId-$i');
          final intermediateMarker = Marker(
            markerId: intermediateMarkerId,
            position: intermediatePosition,
            icon: dotIcon, // Use custom dot icon
            infoWindow: InfoWindow(
              title: 'Location',
              snippet:
                  'Timestamp: ${DateFormat('MM/dd/yyyy hh:mm a').format(intermediateTimestamp)}',
            ),
          );
          _markers.add(intermediateMarker);
        }
      }
    });
  }

  void _zoomToUserLocationHistory(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var location in locations) {
      final latLng = location['position'] as LatLng;
      final lat = latLng.latitude;
      final lng = latLng.longitude;

      if (minLat == null || lat < minLat) minLat = lat;
      if (maxLat == null || lat > maxLat) maxLat = lat;
      if (minLng == null || lng < minLng) minLng = lng;
      if (maxLng == null || lng > maxLng) maxLng = lng;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void _showLocationHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return UserList(
          onUserSelected: (String userId) {
            Navigator.pop(context);
            _pickDateAndShowUserLocationHistory(userId);
          },
        );
      },
    );
  }

  // Method to get current location using Geolocator
  void _addCurrentUserLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied, handle appropriately.
        throw Exception('Location permissions are permanently denied.');
      }

      // Fetch current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      final latitude = position.latitude;
      final longitude = position.longitude;

      // Add a marker to the current location
      final markerId = MarkerId('current_location');
      final marker = Marker(
        markerId: markerId,
        position: LatLng(latitude, longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
        ),
      );

      setState(() {
        _currentUserLocation = LatLng(latitude, longitude);
        _markers.clear();
        _markers.add(marker);
      });

      // Move the camera to the current location
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 15),
      );
    } catch (e) {
      // Use a logging framework instead of print in production code
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            const Text(
              'Parent Home Page',
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            Padding(
              padding:
                  const EdgeInsets.only(right: 8.0), // Add margin to the right
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Map',
                onPressed: _refreshMap,
              ),
            ),
          ],
        ),
      ),
      body: _currentUserLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentUserLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  polylines: _polylines,
                ),
                Positioned(
                  top: 10,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Show Location History',
                        child: FloatingActionButton(
                          onPressed: _showLocationHistory,
                          backgroundColor: Colors.blue,
                          heroTag: "btn1", // Avoid hero tag conflicts
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // Add rounded corners
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history,
                                  color: Colors.white, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10, // Smaller font for label
                                ),
                              ),
                            ],
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
