import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class AcceptedStudentsList extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getAcceptedStudents() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not authenticated");
      return [];
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('parentId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Accepted')
        .get();

    print(
        "Requests Query Result: ${querySnapshot.docs.length} documents found");

    List<Map<String, dynamic>> students = [];

    for (var doc in querySnapshot.docs) {
      final studentID = doc.data()['studentID'];
      final timestamp = doc.data()['timestamp'] as Timestamp?;

      final studentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('studentID', isEqualTo: studentID)
          .get();

      if (studentSnapshot.docs.isNotEmpty) {
        final studentData = studentSnapshot.docs.first.data();
        print("Student Data Found: $studentData");

        // Fetch location data
        final locationSnapshot = await FirebaseFirestore.instance
            .collection('locations')
            .doc(studentSnapshot.docs.first.id)
            .get();

        final locationData =
            locationSnapshot.exists ? locationSnapshot.data() : null;

        students.add({
          ...studentData,
          'timestamp': timestamp,
          'location': locationData,
        });
      } else {
        print("Student Document Not Found: $studentID");
      }
    }

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Locations'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getAcceptedStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No students have accepted your request.'),
            );
          }

          final students = snapshot.data!;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ContactCard(
                contact: student,
                onTap: () {
                  if (student['location'] != null) {
                    final latitude = student['location']['latitude'];
                    final longitude = student['location']['longitude'];
                    final studentName = student['username'];

                    _showLocationOnMap(
                        context, latitude, longitude, studentName);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Location not available for this student."),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showLocationOnMap(BuildContext context, double latitude,
      double longitude, String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows larger height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8, // Map occupies 80% of screen height
          child: Column(
            children: [
              // Draggable Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '$studentName location',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude, longitude),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('student_location'),
                        position: LatLng(latitude, longitude),
                        infoWindow: InfoWindow(title: studentName),
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onTap;

  const ContactCard({
    Key? key,
    required this.contact,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final username = contact['username'] ?? 'Unknown Student';
    final email = contact['email'] ?? 'N/A';
    final imageUrl = contact['profileImage'] ?? '';
    final timestamp = contact['timestamp'] as Timestamp?;

    final formattedTimestamp = timestamp != null
        ? DateFormat('MMMM d, yyyy | h:mm a').format(timestamp.toDate())
        : 'Unknown Timestamp';

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          username,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            const SizedBox(height: 4),
            Text(
              formattedTimestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
