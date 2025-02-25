import 'package:capstone_1/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'set_geofence.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController _eventNameController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  Future<void> _pickDateTime({required bool isStart}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startTime = finalDateTime;
          } else {
            _endTime = finalDateTime;
          }
        });
      }
    }
  }

  Future<void> _submitEvent() async {
    if (_eventNameController.text.isNotEmpty &&
        _startTime != null &&
        _endTime != null) {
      final String eventId =
          FirebaseFirestore.instance.collection('events').doc().id;

      EventModel event = EventModel(
        eventId: eventId,
        eventName: _eventNameController.text,
        startTime: _startTime!,
        endTime: _endTime!,
        teacherId: FirebaseAuth.instance.currentUser!.uid,
        studentIds: [], // Empty for now
        geofenceCenter: const GeoPoint(0.0, 0.0), // Temporary default
        geofenceRadius: 0.0, // Temporary default
        createdAt: DateTime.now(), // Add this line
      );

      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .set(event.toMap());

      // Navigate to set geofence
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetGeofencePage(eventId: eventId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => _pickDateTime(isStart: true),
                  child: const Text('Pick Start Time'),
                ),
                Text(_startTime != null
                    ? _startTime.toString()
                    : 'Not selected'),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _pickDateTime(isStart: false),
                  child: const Text('Pick End Time'),
                ),
                Text(_endTime != null ? _endTime.toString() : 'Not selected'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitEvent,
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
