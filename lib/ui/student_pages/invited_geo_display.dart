import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'geofence_map_view.dart'; // Import the new file

class InvitedGeoDisplay extends StatelessWidget {
  const InvitedGeoDisplay({super.key});

  Future<List<DocumentSnapshot>> _fetchInvitedEvents() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('studentIds', arrayContains: currentUserId)
        .get();

    return eventsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchInvitedEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading events.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No events to display.'));
          }

          final events = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invited Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final geofence = event['geofence'] as Map<String, dynamic>;

                    final GeoPoint center = geofence['center'];
                    final double radius =
                        (geofence['radius'] as num).toDouble();

                    return Card(
                      child: ListTile(
                        title: Text(event['eventName']),
                        subtitle: Text(
                          'Start: ${event['startTime'].toDate()} \n'
                          'End: ${event['endTime'].toDate()}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GeofenceMapView(
                                eventName: event['eventName'],
                                latitude: center.latitude,
                                longitude: center.longitude,
                                radius: radius,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
