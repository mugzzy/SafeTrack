import 'dart:io';

import 'package:capstone_1/ui/More/Profile_pages/accepted_requests_page.dart';
import 'package:capstone_1/ui/student_pages/student_profile/Attendance_report_logs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../More/Profile_pages/emergency_contact_list.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  String? profilePictureUrl;
  String? username;
  String? email;
  String? firstname;
  String? lastname;
  String? address;
  String? birthday;
  String? role;
  String? studentId;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          // Safely extracting data with null checks
          profilePictureUrl = userDoc.data()?['profilePicture'] ?? '';
          username = userDoc.data()?['username'];
          email = userDoc.data()?['email'];
          firstname = userDoc.data()?['firstname'];
          lastname = userDoc.data()?['lastname'];
          address = userDoc.data()?['address'];
          birthday = userDoc.data()?['birthday'];
          role = userDoc.data()?['role'];
          studentId = userDoc.data()?['studentId'];
        });
      } else {
        // Handle the case where the document doesn't exist
        print("User document does not exist.");
      }
    } catch (e) {
      // Catch any errors during the data fetch process
      print("Error fetching user data: $e");
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      String userId = FirebaseAuth.instance.currentUser!.uid;

      try {
        Reference storageRef =
            FirebaseStorage.instance.ref().child('profilePictures/$userId.jpg');
        await storageRef.putFile(file);

        String imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'profilePicture': imageUrl});

        setState(() {
          profilePictureUrl = imageUrl;
        });
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  void _openAcceptedRequestsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AcceptedRequestsPage()),
    );
  }

  void _openEmergencyContactListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyContactListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Curved Box with Profile Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePictureUrl != null &&
                                profilePictureUrl!.isNotEmpty
                            ? NetworkImage(profilePictureUrl!)
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _uploadImage,
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$firstname $lastname',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email ?? 'Email not available',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sections
            _buildSection(
              screenWidth,
              'Manage Location Sharing',
              'List of people who can view your location',
              Icons.location_on,
              _openAcceptedRequestsPage,
            ),
            const SizedBox(height: 10),
            _buildSection(
              screenWidth,
              'Contacts',
              'List of emergency contacts',
              Icons.contacts,
              _openEmergencyContactListPage, // Update to open accepted requests page
            ),
            const SizedBox(height: 10),

            _buildSection(
              screenWidth,
              'Attendance Report Logs',
              'Check Your Attendance Report Logs',
              Icons.calendar_today_rounded,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceReportLogs(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(double width, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
