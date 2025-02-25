import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  DateTime _selectedDay = DateTime.now();
  final List<CalendarEvent> _events = [];
  final CollectionReference _eventsCollection =
      FirebaseFirestore.instance.collection('calendar_events');

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void _fetchEvents() {
    _eventsCollection.snapshots().listen((snapshot) {
      setState(() {
        _events.clear();
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          _events.add(CalendarEvent(
            title: data['title'],
            startTime: (data['startTime'] as Timestamp).toDate(),
            endTime: (data['endTime'] as Timestamp).toDate(),
            location: data['location'],
            description: data['description'],
          ));
        }
      });
    });
  }

  void _addEvent(
      String eventName,
      bool isAllDay,
      DateTime startTime,
      DateTime endTime,
      String location,
      String? description,
      int? someOptionalInt) {
    // Ensure end time is at least one minute after start time
    if (endTime.isBefore(startTime)) {
      endTime = startTime.add(const Duration(minutes: 1));
    }

    var newEvent = CalendarEvent(
      title: eventName,
      startTime: startTime,
      endTime: endTime,
      location: location,
      description: description ?? '', // Handle null
    );

    _events.add(newEvent);
    _eventsCollection.add({
      'title': eventName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'description': description ?? '', // Handle null
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event "$eventName" added!')),
    );
  }

  void _deleteEvent(CalendarEvent event) {
    // Remove from local events list
    setState(() {
      _events.remove(event);
    });

    // Find the document in Firestore by its title and delete it
    _eventsCollection
        .where('title', isEqualTo: event.title) // Assuming title is unique
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event "${event.title}" deleted!')),
    );
  }

  void _editEvent(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: EventDetailPage(
          selectedDay: _selectedDay,
          onSave: (eventName, isAllDay, startTime, endTime, location,
              description, someOptionalInt) {
            // Update event logic here
            setState(() {
              event.title = eventName;
              event.startTime = startTime;
              event.endTime = endTime;
              event.location = location;
              event.description = description ?? '';
            });
            // Update Firestore document as well
            _eventsCollection
                .where('title',
                    isEqualTo: event.title) // Find the existing event
                .get()
                .then((snapshot) {
              for (var doc in snapshot.docs) {
                doc.reference.update({
                  'title': eventName,
                  'startTime': Timestamp.fromDate(startTime),
                  'endTime': Timestamp.fromDate(endTime),
                  'location': location,
                  'description': description ?? '',
                });
              }
            });

            Navigator.pop(context); // Close dialog
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _events
        .where((event) =>
            event.startTime.year == _selectedDay.year &&
            event.startTime.month == _selectedDay.month &&
            event.startTime.day == _selectedDay.day)
        .toList();

    return Scaffold(
      appBar: AppBar( automaticallyImplyLeading: false,
        title: const Text('Events'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 121, 166, 250),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Event',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: EventDetailPage(
                      selectedDay: _selectedDay,
                      onSave: _addEvent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SfCalendar(
              view: CalendarView.month,
              dataSource: EventDataSource(_events),
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.calendarCell) {
                  _selectedDay = details.date!;
                  setState(() {}); // Refresh to show events
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Location: ${event.location}\nDescription: ${event.description}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editEvent(event); // Call edit function
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteEvent(event); // Call delete function
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarEvent {
  String title;
  DateTime startTime;
  DateTime endTime;
  String location;
  String description;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.description,
  });
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<CalendarEvent> source) {
    appointments = source;
  }
}
