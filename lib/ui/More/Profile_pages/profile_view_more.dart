import 'dart:io';

import 'package:capstone_1/services/logout_service.dart';
import 'package:capstone_1/ui/More/Profile_pages/account_settings_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileViewMore extends StatefulWidget {
  final Function onUpdate; // Callback to refresh data after update

  const ProfileViewMore({super.key, required this.onUpdate});

  @override
  _ProfileViewMoreState createState() => _ProfileViewMoreState();
}

class _ProfileViewMoreState extends State<ProfileViewMore> {
  String? backgroundImageUrl;
  String? profilePictureUrl;
  String? username;
  String? firstname;
  String? lastname;
  String? address;
  String? birthday;
  String? email;
  String? role;
  String? studentID;

  final LogoutService _logoutService = LogoutService();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      String userId = FirebaseAuth.instance.currentUser!.uid;

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
    }
  }

  // Fetch user profile from Firestore
  Future<void> _fetchUserProfile() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        backgroundImageUrl = userDoc.data()?['backgroundImage'] ?? '';
        profilePictureUrl = userDoc.data()?['profilePicture'] ?? '';
        username = userDoc.data()?['username'];
        firstname = userDoc.data()?['firstname'];
        lastname = userDoc.data()?['lastname'];
        address = userDoc.data()?['address'];
        birthday = userDoc.data()?['birthday'];
        email = userDoc.data()?['email'];
        role = userDoc.data()?['role'];
        studentID = userDoc.data()?['studentID'];
      });
      print('Fetched Role: $role'); // Debugging line
      print('Fetched Student ID: $studentID'); // Debugging line
    }
  }

  // Upload background image to Firebase Storage
  Future<void> _uploadBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      String userId = FirebaseAuth.instance.currentUser!.uid;

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('backgroundPictures/$userId.jpg');
      await storageRef.putFile(file);

      String imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'backgroundImage': imageUrl});

      setState(() {
        backgroundImageUrl = imageUrl;
      });
    }
  }

  // Open the AccountSettingsModal for editing user profile
  void _openAccountSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AccountSettingsModal(
        profilePictureUrl: profilePictureUrl,
        username: username,
        email: email,
        firstname: firstname,
        lastname: lastname,
        address: address,
        birthday: birthday,
        role: role,
        studentId: studentID,
        onUpdate: _fetchUserProfile, // Refresh data after update
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          children: [
            // Background Image with Upload Option
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.25,
                  decoration: BoxDecoration(
                    image: backgroundImageUrl != null &&
                            backgroundImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(backgroundImageUrl!),
                            fit: BoxFit.cover)
                        : const DecorationImage(
                            image: AssetImage('assets/default_background.jpg'),
                            fit: BoxFit.cover),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: InkWell(
                    onTap: _uploadBackgroundImage,
                    child: CircleAvatar(
                      radius: screenWidth * 0.06,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -screenHeight * 0.06,
                  left: screenWidth * 0.05,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.18,
                        backgroundColor: Colors.grey.shade200,
                        child: CircleAvatar(
                          radius: screenWidth * 0.17,
                          backgroundImage: profilePictureUrl != null &&
                                  profilePictureUrl!.isNotEmpty
                              ? NetworkImage(profilePictureUrl!)
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: screenHeight *
                            0.02, // Adjust this value to move the icon up
                        right: 0,
                        child: InkWell(
                          onTap: _uploadImage,
                          child: CircleAvatar(
                            radius: screenWidth * 0.06,
                            backgroundColor: Colors.blue,
                            child: Padding(
                              padding: EdgeInsets.all(
                                  8.0), // Adjust padding as needed
                              child:
                                  Icon(Icons.camera_alt, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.08),

            // Name and Details Section
            Text(
              '$firstname $lastname',
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            const Divider(thickness: 1, color: Colors.grey),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Details",
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // User Information
            _buildInfoRow("Username:", username, screenWidth),
            _buildInfoRow("Address:", address, screenWidth),
            _buildInfoRow("Birthday:", birthday, screenWidth),
            _buildInfoRow("Email:", email, screenWidth),
            _buildInfoRow("Role:", role, screenWidth),

            // Display Student ID only if role is "student"
            if (role?.toLowerCase() == 'student')
              _buildInfoRow("Student ID:", studentID, screenWidth),

            SizedBox(height: screenHeight * 0.03),

            // Edit Profile Section (Rounded Box)
            GestureDetector(
              onTap: _openAccountSettingsModal,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit,
                        color: Colors.blue, size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for building user info rows
  Widget _buildInfoRow(String label, String? value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        children: [
          Text(
            "$label ",
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style:
                  TextStyle(fontSize: screenWidth * 0.045, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
