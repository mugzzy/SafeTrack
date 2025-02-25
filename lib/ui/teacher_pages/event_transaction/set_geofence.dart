import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'select_student.dart';

class SetGeofencePage extends StatefulWidget {
  final String eventId;

  const SetGeofencePage({Key? key, required this.eventId}) : super(key: key);

  @override
  _SetGeofencePageState createState() => _SetGeofencePageState();
}

class _SetGeofencePageState extends State<SetGeofencePage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  double _radius = 100; // Initial radius in meters
  Circle? _geofenceCircle;
  LatLng? _geofenceCenter;
  bool _isCenterLocked = false; // Lock state for the center
  final TextEditingController _radiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _radiusController.text = _radius.toStringAsFixed(0); // Initialize the field
    _getUserLocation();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  // Get the user's current location
  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _geofenceCenter = _currentPosition;
      _updateGeofenceCircle();
    });
  }

  // Update the visual geofence circle
  void _updateGeofenceCircle() {
    setState(() {
      _geofenceCircle = Circle(
        circleId: const CircleId('geofence'),
        center: _geofenceCenter!,
        radius: _radius,
        strokeColor: Colors.blueAccent,
        strokeWidth: 2,
        fillColor: Colors.blueAccent.withOpacity(0.3),
      );
    });
  }

  // Lock the camera to the geofence center
  void _lockCameraToCenter() {
    if (_mapController != null && _geofenceCenter != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_geofenceCenter!),
      );
    }
  }

  // Save geofence information to Firestore
  Future<void> _submitGeofence() async {
    if (_geofenceCenter != null && _radius > 0) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'geofence': {
          'center':
              GeoPoint(_geofenceCenter!.latitude, _geofenceCenter!.longitude),
          'radius': _radius,
        },
      });

      // Navigate to select students
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectStudentsPage(eventId: widget.eventId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set the geofence correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Geofence')),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  circles: _geofenceCircle != null ? {_geofenceCircle!} : {},
                  onCameraMove: (CameraPosition position) {
                    // Update the geofence center only if it is not locked
                    if (!_isCenterLocked) {
                      setState(() {
                        _geofenceCenter = position.target;
                        _updateGeofenceCircle();
                      });
                    }
                  },
                ),
                // Center marker
                const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.location_on, size: 40, color: Colors.red),
                ),
                // "Set Geofence" button in the upper-right corner
                Positioned(
                  top: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _submitGeofence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Blue color for the button
                    ),
                    child: const Text('Set Geofence'),
                  ),
                ),
                // Slider, TextField, and lock button
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        min: 10, // Minimum radius set to 10 meter
                        max: 1000,
                        divisions: 100,
                        value: _radius,
                        label: _radius.toStringAsFixed(0),
                        onChanged: (value) {
                          setState(() {
                            _radius = value;
                            _radiusController.text =
                                _radius.toStringAsFixed(0); // Sync field
                            _updateGeofenceCircle();
                          });
                          if (_isCenterLocked) {
                            _lockCameraToCenter();
                          }
                        },
                      ),
                      // TextField with white background
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _radiusController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Radius (meters)',
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              // Check if the entered value is a valid number
                              double? typedRadius = double.tryParse(value);
                              if (typedRadius != null) {
                                // Enforce minimum and maximum limits
                                if (typedRadius > 1000) {
                                  typedRadius = 1000;
                                  _radiusController.text = '1000';
                                } else if (typedRadius < 10) {
                                  typedRadius = 10;
                                  _radiusController.text = '1';
                                }

                                // Update the controller's text and cursor position
                                _radiusController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: _radiusController.text.length),
                                );

                                setState(() {
                                  _radius = typedRadius!;
                                  _updateGeofenceCircle();
                                });

                                if (_isCenterLocked) {
                                  _lockCameraToCenter();
                                }
                              } else if (value.isNotEmpty) {
                                // If the value is not a valid number and it's not empty, reset to the previous valid value
                                _radiusController.text =
                                    _radius.toStringAsFixed(0);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isCenterLocked = !_isCenterLocked;
                            if (_isCenterLocked) {
                              _lockCameraToCenter();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isCenterLocked ? Colors.green : Colors.red,
                        ),
                        child: Text(
                            _isCenterLocked ? 'Unlock Center' : 'Lock Center'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
