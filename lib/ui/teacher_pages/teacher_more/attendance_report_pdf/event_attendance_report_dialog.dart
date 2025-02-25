import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report_generator/pdf_event_generator.dart';
import 'package:flutter/material.dart';

class EventAttendanceReportDialog extends StatelessWidget {
  final String reportTitle;
  final DateTime eventDate;
  final List<Map<String, dynamic>> eventData;

  const EventAttendanceReportDialog({
    super.key,
    required this.reportTitle,
    required this.eventDate,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Event Attendance Report',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.black87,
        ),
      ),
      content: const Text(
        'Choose an option to view, share, or save the event attendance report.',
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await EventPDFGenerator.generateEventWiseAttendanceReport(
              reportTitle: reportTitle,
              eventDate: eventDate,
              eventData: eventData,
              context: context,
              share: true,
            );
          },
          icon: Icon(Icons.share, color: Colors.blue),
          label: Text(
            'View/Share',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
