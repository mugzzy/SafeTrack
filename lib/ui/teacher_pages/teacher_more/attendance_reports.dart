import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report/early_late_report.dart';
import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report/event_wise_attendance.dart';
import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report/month_wise_attendance.dart';
import 'package:flutter/material.dart';

class AttendanceReportsPage extends StatelessWidget {
  const AttendanceReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Reports"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // First report section: "By Designation"
            // _buildReportSection(
            //   screenWidth,
            //   "Events Wise Attendance",
            //   "Upcoming feature",
            //   Icons.work_outline,
            //   () {
            //     //
            //   },
            // ),
            const SizedBox(height: 16),
            _buildReportSection(
              screenWidth,
              "Early Bird & Late Show Report",
              "View early and late attendance",
              Icons.access_time,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EarlyLateReportPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            _buildReportSection(
              screenWidth,
              "Events Wise Attendance",
              "Attendance by event",
              Icons.event_note_sharp,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventWiseAttendance(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Second report section: "Month Wise Attendance"
            _buildReportSection(
              screenWidth,
              "Month Event Wise Attendance",
              "Attendance of the month events",
              Icons.calendar_today_outlined,
              () {
                // Navigate to the MonthWiseAttendancePage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonthWiseAttendancePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // _buildReportSection now accepts the onTap function
  Widget _buildReportSection(
    double width,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, // Accept onTap callback here
  ) {
    return GestureDetector(
      onTap: onTap, // Call onTap when the section is tapped
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold, // Bold title
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
