import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report_generator/pdf_month_generator.dart';
import 'package:flutter/material.dart';

class AttendanceReportDialog extends StatelessWidget {
  final String eventName; // Event name passed from the parent widget
  final Map<String, String> studentAttendance; // Attendance data

  const AttendanceReportDialog({
    super.key,
    required this.eventName,
    required this.studentAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Attendance Report',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.black87,
        ),
      ),
      content: const Text(
        'Choose an option below to generate, view, share, or save the attendance report.',
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
      actions: [
        // Generate and View Report Button
        TextButton.icon(
          onPressed: () async {
            Navigator.of(context).pop(); // Close the dialog
            try {
              await PDFGenerator.generateAttendanceReport(
                eventName: eventName,
                studentAttendance: studentAttendance,
                context: context,
                share: false, // Generate without sharing
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF generated successfully!')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error generating report: $e')),
              );
            }
          },
          icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
          label: const Text(
            'Generate Report',
            style: TextStyle(color: Colors.blue),
          ),
        ),
        // Share Report Button
        TextButton.icon(
          onPressed: () async {
            Navigator.of(context).pop(); // Close the dialog
            try {
              await PDFGenerator.generateAttendanceReport(
                eventName: eventName,
                studentAttendance: studentAttendance,
                context: context,
                share: true, // Generate and share
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sharing report: $e')),
              );
            }
          },
          icon: const Icon(Icons.share, color: Colors.green),
          label: const Text(
            'Share Report',
            style: TextStyle(color: Colors.green),
          ),
        ),
        // Cancel Button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
