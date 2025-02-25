import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceMapView extends StatelessWidget {
  final String eventName;
  final double latitude;
  final double longitude;
  final double radius;

  const GeofenceMapView({
    super.key,
    required this.eventName,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(eventName),
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
                latitude.toDouble(), longitude.toDouble()), // Convert to double
            zoom: 16,
          ),
          markers: {
            Marker(
              markerId: MarkerId(eventName),
              position: LatLng(latitude.toDouble(),
                  longitude.toDouble()), // Convert to double
              infoWindow: InfoWindow(title: eventName),
            ),
          },
          circles: {
            Circle(
              circleId: CircleId(eventName),
              center: LatLng(latitude.toDouble(),
                  longitude.toDouble()), // Convert to double
              radius: radius.toDouble(), // Convert to double
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          },
        ));
  }
}
