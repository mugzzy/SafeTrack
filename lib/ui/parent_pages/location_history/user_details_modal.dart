import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserDetailsModal extends StatefulWidget {
  final String userId;
  final String email;
  final void Function(String userId) onViewLocationHistory;

  const UserDetailsModal({
    Key? key,
    required this.userId,
    required this.email,
    required this.onViewLocationHistory,
  }) : super(key: key);

  @override
  _UserDetailsModalState createState() => _UserDetailsModalState();
}

class _UserDetailsModalState extends State<UserDetailsModal> {
  String backgroundImageUrl = '';
  String profilePictureUrl = '';

  // Fetch user profile details from Firestore
  Future<Map<String, String?>> _fetchUserDetails(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        final data = snapshot.data();
        return {
          'profileImage':
              data?['profileImage'] ?? 'assets/images/default_profile.png',
          'username': data?['username'] ?? 'Unknown',
          'studentID': data?['studentID'] ?? 'No Student ID',
        };
      }
    } catch (e) {
      print('Error: $e');
    }
    return {};
  }

  // Fetch user profile from Firestore and update state
  Future<void> _fetchUserProfile() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        backgroundImageUrl = userDoc.data()?['backgroundImage'] ?? '';
        profilePictureUrl = userDoc.data()?['profilePicture'] ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user profile on widget initialization
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _fetchUserDetails(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final userDetails = snapshot.data!;
        final profileImage = userDetails['profileImage']!;
        final username = userDetails['username']!;
        final studentID = userDetails['studentID']!;

        return Container(
          padding: const EdgeInsets.all(12.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profileImage),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.email,
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6.0),
                    Text('Username: $username',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 6.0),
                    Text('Student ID: $studentID',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12.0),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onViewLocationHistory(widget.userId);
                      },
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: const Text('View Location History',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
