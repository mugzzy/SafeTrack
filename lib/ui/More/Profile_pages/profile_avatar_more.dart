import 'dart:io';

import 'package:capstone_1/ui/More/Profile_pages/profile_view_more.dart';
import 'package:capstone_1/ui/teacher_pages/teacher_more/teachers_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileAvatarMore extends StatefulWidget {
  const ProfileAvatarMore({super.key});

  @override
  _ProfileAvatarMoreState createState() => _ProfileAvatarMoreState();
}

class _ProfileAvatarMoreState extends State<ProfileAvatarMore> {
  String? profilePictureUrl;
  String? username;
  String? email;
  String? firstname;
  String? lastname;
  String? address;
  String? birthday;
  String? role;

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);

      // Upload image to Firebase Storage
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profilePictures/$userId.jpg');
      await storageRef.putFile(file);

      // Get the download URL for the image
      String imageUrl = await storageRef.getDownloadURL();

      // Update Firestore with the new profile picture URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'profilePicture': imageUrl});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error fetching user data.'));
        }

        var userDoc = snapshot.data;

        // Null safe check for profilePicture field existence
        profilePictureUrl = userDoc?.data() != null &&
                (userDoc!.data() as Map<String, dynamic>)
                    .containsKey('profilePicture')
            ? userDoc['profilePicture']
            : '';

        username = userDoc?['username'];
        email = userDoc?['email'];
        firstname = userDoc?['firstname'];
        lastname = userDoc?['lastname'];
        address = userDoc?['address'];
        birthday = userDoc?['birthday'];
        role = userDoc?['role'];

        return Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
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
                  GestureDetector(
                    onTap: () {
                      _navigateToProfileView();
                    },
                    child: Text(
                      '$firstname $lastname',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      _navigateToProfileView();
                    },
                    child: Text(
                      email ?? 'Email not available',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // Ensures the background is circular
                  color: Colors.blue, // Background color for the button
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications,
                      color: Colors.white), // White icon color
                  onPressed: () {
                    // Check if role is 'Teacher' before navigating
                    if (role == 'Teacher') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TeachersNotificationPage()),
                      );
                    } else {
                      // Optionally, show a message or do nothing
                      debugPrint("Not a Teacher. No action taken.");
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Navigate to the Parent Profile View screen
  void _navigateToProfileView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewMore(
          onUpdate: () {}, // You can handle update if needed
        ),
      ),
    );
  }
}
