import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report_pdf/event_attendance_report_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class EventWiseAttendance extends StatefulWidget {
  const EventWiseAttendance({super.key});

  @override
  _EventWiseAttendanceState createState() => _EventWiseAttendanceState();
}

class _EventWiseAttendanceState extends State<EventWiseAttendance> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _eventAttendanceData = [];

  // Fetch attendance data for the selected date
  Future<void> _fetchAttendanceData(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(date);

      // Fetch events for the selected date
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('startTime', isGreaterThanOrEqualTo: date)
          .where('startTime', isLessThan: date.add(const Duration(days: 1)))
          .get();

      List<Map<String, dynamic>> eventData = [];

      for (var eventDoc in eventSnapshot.docs) {
        String eventName = eventDoc['eventName'];
        List<dynamic> studentIds = eventDoc['studentIds'] ?? [];

        // Fetch attendance records for the event
        QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
            .collection('attendance')
            .doc(dateString)
            .collection(eventName)
            .get();

        int presentCount = attendanceSnapshot.docs.length;
        int absentCount = studentIds.length - presentCount;

        eventData.add({
          'eventName': eventName,
          'participants': studentIds.length,
          'present': presentCount,
          'absent': absentCount,
        });
      }

      setState(() {
        _eventAttendanceData = eventData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Open calendar picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      await _fetchAttendanceData(pickedDate);
    }
  }

  // Open the EventAttendanceReportDialog
  void _generatePdf() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventAttendanceReportDialog(
          reportTitle: 'Event Wise Attendance Report',
          eventDate: _selectedDate,
          eventData: _eventAttendanceData,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Wise Attendance'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text
            const Text(
              'Select a Date',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),

            // Calendar Dropdown and PDF Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date Selection Button
                ElevatedButton(
                  onPressed: _selectDate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // PDF Icon Button
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf,
                      color: Colors.blueAccent),
                  onPressed: _eventAttendanceData.isNotEmpty
                      ? _generatePdf
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No data available to generate a report.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Show loading animation while fetching data
            if (_isLoading)
              Center(
                child: SpinKitChasingDots(
                  color: Colors.blueAccent,
                  size: 50.0,
                ),
              ),

            // Display Event Attendance Data
            if (!_isLoading && _eventAttendanceData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _eventAttendanceData.length,
                  itemBuilder: (context, index) {
                    var event = _eventAttendanceData[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(event['eventName']),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Participants: ${event['participants']}'),
                            Text('Present: ${event['present']}'),
                            Text('Absent: ${event['absent']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Display message if no events found
            if (!_isLoading && _eventAttendanceData.isEmpty)
              const Center(
                child: Text('No events found for the selected date.'),
              ),
          ],
        ),
      ),
    );
  }
}
