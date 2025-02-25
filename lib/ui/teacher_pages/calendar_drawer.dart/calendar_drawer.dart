import 'package:capstone_1/models/event_model.dart';
import 'package:capstone_1/ui/teacher_pages/calendar_drawer.dart/calendar_attendance.dart';
import 'package:capstone_1/ui/teacher_pages/calendar_drawer.dart/calendar_student.dart';
import 'package:capstone_1/ui/teacher_pages/event_transaction/select_student.dart';
import 'package:flutter/material.dart';

class CalendarDrawer extends StatelessWidget {
  final EventModel event;

  const CalendarDrawer({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            screenWidth * 0.05, // 5% of screen width for horizontal padding
        vertical:
            screenHeight * 0.02, // 2% of screen height for vertical padding
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: screenWidth * 0.1, // 10% of screen width for the bar
            margin: EdgeInsets.only(bottom: screenHeight * 0.02), // Spacing
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Display the event name dynamically
          Text(
            'Manage "${event.eventName}" Event',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenHeight * 0.025, // Scaled font size
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02), // 2% of screen height spacing
          ListTile(
            leading: Icon(Icons.playlist_add_check, size: screenHeight * 0.03),
            title: Text(
              'Attendance',
              style:
                  TextStyle(fontSize: screenHeight * 0.02), // Adjust font size
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CalendarAttendancePage(
                    eventId: event.eventId,
                    eventName: event.eventName,
                    eventDate: _getEventDate(event.startTime),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.group, size: screenHeight * 0.03),
            title: Text(
              'Students',
              style: TextStyle(fontSize: screenHeight * 0.02),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CalendarInvitedPage(eventId: event.eventId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add, size: screenHeight * 0.03),
            title: Text(
              'Add Student',
              style: TextStyle(fontSize: screenHeight * 0.02),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SelectStudentsPage(
                    eventId: event.eventId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getEventDate(DateTime startTime) {
    return startTime.toIso8601String().split('T').first; // Returns 'YYYY-MM-DD'
  }
}
