import 'package:capstone_1/ui/teacher_pages/event_transaction/create_event.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddContentPage extends StatefulWidget {
  const AddContentPage({super.key});

  @override
  _AddContentPageState createState() => _AddContentPageState();
}

class _AddContentPageState extends State<AddContentPage> {
  String _username = 'User'; // Default name

  @override
  void initState() {
    super.initState();
    _getCurrentUserDetails();
  }

  // Get the current user's first name from Firestore
  Future<void> _getCurrentUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid; // Get the user's ID from Firebase Auth

      try {
        // Retrieve the user's document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc[
                'firstname']; // Use the 'firstname' field from Firestore
          });
        }
      } catch (e) {
        // Handle errors (e.g., document doesn't exist)
        print('Error fetching user details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         automaticallyImplyLeading: false,
        title: const Text('Create Event'),
      ),
      body: Center(
        // Center the content
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hi $_username, are you ready to start an event?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the CreateEventPage when the button is clicked
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateEventPage(),
                    ),
                  );
                },
                child: const Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
