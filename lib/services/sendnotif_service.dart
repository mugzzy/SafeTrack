import 'package:capstone_1/models/sendnotif_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'cache_service.dart'; // Import your CacheService

class MethodsSendNotif {
  final SendNotifModel model;
  final CacheService cacheService = CacheService(); // Instantiate CacheService
  final User? user = FirebaseAuth.instance.currentUser;

  MethodsSendNotif({required this.model});

  Future<List<Map<String, dynamic>>> _fetchOngoingEvents() async {
    final now = DateTime.now();
    print("Current time: $now");

    final querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('startTime', isLessThanOrEqualTo: now)
        .where('endTime', isGreaterThanOrEqualTo: now)
        .get();

    print("Fetched ${querySnapshot.docs.length} potential ongoing events");

    List<Map<String, dynamic>> ongoingEvents = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      List<dynamic> studentIds = data['studentIds'] ?? [];
      String teacherId = data['teacherId'] ?? '';

      print("Teacher ID: $teacherId");

      if (studentIds.contains(user?.uid)) {
        print("Logged-in student (${user?.uid}) is part of this event");
        ongoingEvents.add({
          'eventName': data['eventName'] as String,
          'teacherId': teacherId,
        });
      } else {
        print("Logged-in student (${user?.uid}) is NOT part of this event");
      }
    }

    print(
        "Total ongoing events for the logged-in student: ${ongoingEvents.length}");
    return ongoingEvents;
  }

  // Method to fetch the logged-in user's email and studentID
  void getLoggedInUserEmail() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      model.loggedInUserEmail = user.email;

      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          var userData = userSnapshot.data() as Map<String, dynamic>;
          model.loggedInUserStudentId = userData['studentID'];

          // Fetch ongoing events
          List<Map<String, dynamic>> ongoingEvents =
              await _fetchOngoingEvents();
          if (ongoingEvents.isNotEmpty) {
            print("Ongoing events for student: $ongoingEvents");
          } else {
            print("No ongoing events found.");
          }

          await fetchLocationDataAndSetTemplate(); // Fetch location data
        } else {
          ScaffoldMessenger.of(model.context).showSnackBar(
            const SnackBar(content: Text('User data not found in Firestore')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(model.context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(model.context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  // Method to fetch the location data from Firestore
  Future<void> fetchLocationDataAndSetTemplate() async {
    final User? user =
        FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      model.isLoading = true;
      try {
        // Fetch user details
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userSnapshot.exists) {
          model.isLoading = false;
          ScaffoldMessenger.of(model.context).showSnackBar(
            const SnackBar(content: Text('User data not found in Firestore')),
          );
          return;
        }

        var userData = userSnapshot.data() as Map<String, dynamic>;
        String username = userData['username'] ?? 'Unknown';

        // Fetch location details
        DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
            .collection('locations')
            .doc(user.uid) // Use UID for the document ID
            .get();

        if (locationSnapshot.exists) {
          var locationData = locationSnapshot.data() as Map<String, dynamic>;

          // Handle potential null values
          double? latitude = locationData['latitude'];
          double? longitude = locationData['longitude'];
          Timestamp? timestamp = locationData['timestamp'];

          if (latitude != null && longitude != null && timestamp != null) {
            // Format the timestamp
            DateTime dateTime = timestamp.toDate();
            String formattedDate = DateFormat('MMMM dd, yyyy').format(dateTime);
            String formattedTime =
                DateFormat('hh:mm a').format(dateTime); // 12-hour format

            String helpMessageTemplate = 'Emergency Alert!\n\n'
                '$username has triggered an emergency notification.\n'
                'Last known location recorded on $formattedDate at $formattedTime.\n'
                'Coordinates: Latitude: $latitude, Longitude: $longitude\n\n'
                'Please take immediate action if necessary!';

            model.setState(() {
              model.isLoading = false;
              model.controller.text = helpMessageTemplate;
            });
          } else {
            model.isLoading = false;
            ScaffoldMessenger.of(model.context).showSnackBar(
              const SnackBar(content: Text('Incomplete location data')),
            );
          }
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(model.context).showSnackBar(
            const SnackBar(content: Text('No location data found')),
          );
        }
      } catch (e) {
        model.isLoading = false; // Reset loading state
        ScaffoldMessenger.of(model.context).showSnackBar(
          SnackBar(content: Text('Error fetching location data: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(model.context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchAcceptedContacts() async {
    if (model.loggedInUserStudentId == null) {
      print("No student ID found for the logged-in user.");
      return [];
    }

    try {
      print(
          "Fetching accepted contacts for student ID: ${model.loggedInUserStudentId}");

      QuerySnapshot requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'Accepted')
          .where('studentID', isEqualTo: model.loggedInUserStudentId)
          .get();

      List<Map<String, dynamic>> contacts = [];

      for (var doc in requestsSnapshot.docs) {
        var requestData = doc.data() as Map<String, dynamic>;
        String parentId = requestData['parentId'];

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(parentId)
            .get();

        if (userSnapshot.exists) {
          var userData = userSnapshot.data() as Map<String, dynamic>;

          if (userData['role'] == 'Parent') {
            // Ensure only "Parent" contacts are included
            Map<String, dynamic> contact = {
              'parentId': parentId,
              'email': userData['email'] ?? '',
            };

            contacts.add(contact);
            print("Added Parent Contact: $contact");
          } else {
            print("Skipped non-parent user: $parentId");
          }
        } else {
          print("Parent user not found in Firestore: $parentId");
        }
      }

      print("Final List of Accepted Parent Contacts: $contacts");
      return contacts;
    } catch (e) {
      print("Error fetching contacts: $e");
      ScaffoldMessenger.of(model.context).showSnackBar(
        SnackBar(content: Text('Error fetching contacts: $e')),
      );
      return [];
    }
  }

// sending the Emergency Message
  void sendEmergencyNotification() async {
    if (model.controller.text.trim().isEmpty) {
      model.setState(() {
        model.hasError = true;
      });
      ScaffoldMessenger.of(model.context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(model.context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Fetch only accepted contacts with role "Parent"
      List<Map<String, dynamic>> acceptedContacts =
          await fetchAcceptedContacts();
      print("Accepted Parent Contacts: $acceptedContacts");

      // Ensure selected contacts are only from accepted contacts
      List<Map<String, dynamic>> validRecipients = acceptedContacts
          .map((contact) => {
                'parentId': contact['parentId'],
                'status': 'unseen',
              })
          .toList();

      if (validRecipients.isEmpty) {
        print("No valid recipients selected.");
        ScaffoldMessenger.of(model.context).showSnackBar(
          const SnackBar(content: Text('No valid recipients available')),
        );
        return;
      }

      // Fetch ongoing events to get the associated teacherId
      List<Map<String, dynamic>> ongoingEvents = await _fetchOngoingEvents();

      // Extract the teacherId (assuming one event per student at a time)
      Map<String, dynamic>? teacherInfo;
      if (ongoingEvents.isNotEmpty) {
        String teacherId = ongoingEvents.first['teacherId'];
        teacherInfo = {
          'teacherId': teacherId,
          'status': 'unseen', // Set initial teacher status
        };
      }

      // Construct the notification data
      Map<String, dynamic> notificationData = {
        'userEmail': model.loggedInUserEmail,
        'userId': user.uid,
        'message': model.controller.text.trim(),
        'recipients': validRecipients,
        'timestamp': Timestamp.now(),
        if (teacherInfo != null)
          'teacher': teacherInfo, // Add teacher if available
      };

      await FirebaseFirestore.instance
          .collection('student_notifications')
          .add(notificationData);

      print("Emergency notification sent successfully.");
      print("Recipients: $validRecipients");
      print("Teacher: $teacherInfo");

      ScaffoldMessenger.of(model.context).showSnackBar(
        const SnackBar(
            content: Text('Emergency notification sent successfully')),
      );
    } catch (e) {
      print("Failed to send notification: $e");
      ScaffoldMessenger.of(model.context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }
}
