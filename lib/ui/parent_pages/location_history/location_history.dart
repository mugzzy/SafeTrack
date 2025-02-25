import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHistory extends StatelessWidget {
  final String userId;

  LocationHistory({required this.userId});

  Future<Map<String, dynamic>> _getUserDetails() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final userData = userDoc.data();
      return {
        'username': userData?['username'] ?? 'Unknown User',
        'email': userData?['email'] ?? 'No Email'
      };
    }
    return {'username': 'Unknown User', 'email': 'No Email'};
  }

  Future<List<LatLng>> _getLocationHistory() async {
    List<LatLng> locations = [];
    final historySnapshot = await FirebaseFirestore.instance
        .collection('location_history')
        .doc(userId)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .get();

    for (var doc in historySnapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      if (lat != null && lng != null) {
        locations.add(LatLng(lat, lng));
      }
    }
    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserDetails(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (userSnapshot.hasError || !userSnapshot.hasData) {
          return Center(child: Text('Error fetching user details'));
        } else {
          final user = userSnapshot.data!;
          return FutureBuilder<List<LatLng>>(
            future: _getLocationHistory(),
            builder: (context, locationSnapshot) {
              if (locationSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (locationSnapshot.hasError) {
                return Center(child: Text('Error fetching location history'));
              } else if (!locationSnapshot.hasData ||
                  locationSnapshot.data!.isEmpty) {
                return Center(child: Text('No location history available'));
              } else {
                final locations = locationSnapshot.data!;
                return Container(
                  padding: EdgeInsets.all(16),
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User: ${user['username']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Email: ${user['email']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final loc = locations[index];
                            return ListTile(
                              leading: Icon(Icons.location_on),
                              title: Text(
                                  'Lat: ${loc.latitude}, Lng: ${loc.longitude}'),
                              trailing: index > 0
                                  ? Icon(Icons.arrow_downward)
                                  : SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        }
      },
    );
  }
}
