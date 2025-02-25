import 'package:capstone_1/ui/teacher_pages/calendar_drawer.dart/calendar_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';

import '../../models/event_model.dart'; // Import EventModel

class CalendarPage extends StatefulWidget {
  final Function(EventModel) onEventSelected; // Callback

  const CalendarPage({super.key, required this.onEventSelected}); // Constructor

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<EventModel> _events = []; // Store the events

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Fetch events on initialization
  }

  // Fetch events created by the logged-in teacher
  Future<void> _fetchEvents() async {
    try {
      // Get the current user's UID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Query Firestore for events where teacherId matches the current user's UID
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('teacherId', isEqualTo: userId)
          .get();

      setState(() {
        // Map the Firestore documents to EventModel instances
        _events =
            snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList();

        // Sort the events by creation time (assuming createdAt is a DateTime field)
        _events.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt)); // Latest to oldest
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  // Delete an event from Firestore and the local list
  Future<void> _deleteEvent(EventModel event) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.eventId) // Use the unique document ID
          .delete();

      setState(() {
        _events.remove(event); // Remove from the local list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully.')),
      );
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete event.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Event Calendar'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Here are your events:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _events.isEmpty
                  ? const Text('No events found.')
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return Dismissible(
                            key: Key(event.eventId), // Use the unique eventId
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              // Show a confirmation dialog
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Event'),
                                    content: const Text(
                                        'Are you sure you want to delete this event?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              _deleteEvent(event);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.eventName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _getEventStatus(
                                          event.startTime,
                                          event
                                              .endTime), // Status text below event name
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            event.startTime, event.endTime),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.menu_rounded),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) =>
                                          CalendarDrawer(event: event),
                                      isScrollControlled: true,
                                    );
                                  },
                                ),
                                onTap: () {
                                  widget.onEventSelected(
                                      event); // Call the callback
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Get the status of the event (Ongoing, Ended, or Upcoming)
  String _getEventStatus(DateTime startTime, DateTime endTime) {
    DateTime now = DateTime.now();
    if (now.isBefore(startTime)) {
      return 'Upcoming';
    } else if (now.isAfter(endTime)) {
      return 'Ended';
    } else {
      return 'Ongoing';
    }
  }

  // Get the status color for event cards
  Color _getStatusColor(DateTime startTime, DateTime endTime) {
    DateTime now = DateTime.now();
    if (now.isBefore(startTime)) {
      return Colors.green;
    } else if (now.isAfter(endTime)) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }
}
