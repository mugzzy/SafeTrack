import 'dart:io'; // Import for File class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePictureUpload extends StatefulWidget {
  const ProfilePictureUpload({super.key});

  @override
  _ProfilePictureUploadState createState() => _ProfilePictureUploadState();
}

class _ProfilePictureUploadState extends State<ProfilePictureUpload> {
  String? profilePictureUrl;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery); // Update to pickImage

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Upload image to Firebase Storage
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profilePictures/$userId.jpg');
      await storageRef.putFile(file);

      // Get the download URL
      String imageUrl = await storageRef.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'profilePicture': imageUrl});
      setState(() {
        profilePictureUrl = imageUrl; // Update the state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: profilePictureUrl != null
              ? NetworkImage(profilePictureUrl!)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        ElevatedButton(
          onPressed: _uploadImage,
          child: const Text('Upload Profile Picture'),
        ),
      ],
    );
  }
}
