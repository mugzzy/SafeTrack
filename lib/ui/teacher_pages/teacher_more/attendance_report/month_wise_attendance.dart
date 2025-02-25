import 'package:capstone_1/ui/teacher_pages/teacher_more/attendance_report_pdf/month_attendance_report_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MonthWiseAttendancePage extends StatefulWidget {
  const MonthWiseAttendancePage({super.key});

  @override
  _MonthWiseAttendancePageState createState() =>
      _MonthWiseAttendancePageState();
}

class _MonthWiseAttendancePageState extends State<MonthWiseAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedEvent;
  List<String> _events = [];
  List<String> _studentIds = [];
  Map<String, String> _studentIDs =
      {}; // Add this line to store studentUID to studentID mapping
  Map<String, String> _studentAttendanceStatus =
      {}; // Store student attendance status
  bool _isLoading = false;

  // Fetch events for the selected date
  // Fetch events for the selected date, including from both "events" and "attendance" collections
  Future<void> _fetchEventsForDate(DateTime date) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Fetch events from the "events" collection
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('startTime', isGreaterThanOrEqualTo: date)
          .where('startTime', isLessThan: date.add(const Duration(days: 1)))
          .get();

      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(date.toIso8601String().split('T').first) // Use date without time
          .collection('events')
          .get();

      // Combine events from both collections
      List<String> combinedEvents = [];

      // Add events from the "events" collection
      combinedEvents.addAll(
        eventSnapshot.docs.map((doc) => doc['eventName'] as String),
      );

      // Add events from the "attendance" collection if not already included
      attendanceSnapshot.docs.forEach((doc) {
        String eventName =
            doc.id; // The event name is the document ID in this case
        if (!combinedEvents.contains(eventName)) {
          combinedEvents.add(eventName);
        }
      });

      // Update the dropdown with combined events
      setState(() {
        _events = combinedEvents.isEmpty ? ["No events"] : combinedEvents;
        _selectedEvent = _events.isNotEmpty ? _events.first : null;
      });
    } catch (e) {
      setState(() {
        _events = ["Error fetching events"];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // Fetch studentIds for the selected event and get their studentID from users collection
  Future<void> _fetchStudentsForEvent(String eventName) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Fetch event details to get studentIds
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('eventName', isEqualTo: eventName)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        var eventData = eventSnapshot.docs.first.data() as Map<String, dynamic>;
        _studentIds = List<String>.from(eventData['studentIds'] ?? []);
        print('Fetched studentIds: $_studentIds'); // Debugging line

        // Fetch studentID for each studentUID
        for (String studentId in _studentIds) {
          String studentID = await _getStudentID(studentId); // Fetch studentID
          setState(() {
            _studentIDs[studentId] = studentID; // Store studentID mapping
          });

          // Check attendance for each student
          String attendanceStatus =
              await _checkAttendanceForStudent(studentId, eventName);
          setState(() {
            _studentAttendanceStatus[studentId] =
                attendanceStatus; // Store student attendance status
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students for event: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // Fetch studentID from the users collection using studentUID
  Future<String> _getStudentID(String studentId) async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();
      if (studentDoc.exists) {
        var studentData = studentDoc.data() as Map<String, dynamic>;
        return studentData['studentID'] ??
            'Unknown'; // Fetch studentID from user data
      }
    } catch (e) {
      return 'Unknown';
    }
    return 'Unknown';
  }

  // Check if the student has attendance record for the selected event
  Future<String> _checkAttendanceForStudent(
      String studentId, String eventName) async {
    String date = _selectedDate
        .toIso8601String()
        .split('T')
        .first; // Get the current date as string (e.g., 2024-12-17)
    try {
      DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(date)
          .collection(eventName)
          .doc(studentId)
          .get();

      if (attendanceDoc.exists) {
        return 'Present';
      } else {
        return 'Absent';
      }
    } catch (e) {
      return 'Absent'; // Default to absent in case of error
    }
  }

  // Open calendar picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      await _fetchEventsForDate(pickedDate);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEventsForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Month-Wise Attendance'),
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
              'Select a Date and Event',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),

            // Calendar Dropdown and Search Icon
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
                      Icon(Icons.calendar_today, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // PDF Icon Button - Opens the dialog
                IconButton(
                  onPressed: () {
                    if (_selectedEvent != null &&
                        _studentAttendanceStatus.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AttendanceReportDialog(
                            eventName: _selectedEvent!,
                            studentAttendance:
                                _studentAttendanceStatus.map((key, value) {
                              String studentID = _studentIDs[key] ?? 'Unknown';
                              return MapEntry(studentID, value);
                            }),
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'No data available to generate a report.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf,
                      color: Colors.blueAccent),
                ),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: Colors.blueAccent),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Event Dropdown with custom styling
            const Text(
              'Select an Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedEvent,
                items: _events.map((event) {
                  return DropdownMenuItem(
                    value: event,
                    child: Text(
                      event,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEvent = value;
                    if (_selectedEvent != null) {
                      _fetchStudentsForEvent(value!);
                    }
                  });
                },
                hint: const Text(
                  'Select an event',
                  style: TextStyle(color: Colors.black45),
                ),
                underline: const SizedBox(),
              ),
            ),
            const SizedBox(height: 16),

            // Show loading animation while fetching data
            if (_isLoading)
              Center(
                child: SpinKitChasingDots(
                  color: Colors.blueAccent, // First dot color (blue)
                  size: 50.0,
                ),
              ),

            // Display Student IDs and Attendance Status
            if (_selectedEvent != null && _studentIds.isNotEmpty && !_isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: _studentIds.length,
                  itemBuilder: (context, index) {
                    String studentId = _studentIds[index];
                    String studentID =
                        _studentIDs[studentId] ?? 'Unknown'; // Fetch studentID
                    String attendanceStatus =
                        _studentAttendanceStatus[studentId] ?? 'Absent';

                    // Set the color based on attendance status
                    Color attendanceColor = attendanceStatus == 'Present'
                        ? Colors.green
                        : Colors.red;
                    IconData attendanceIcon = attendanceStatus == 'Present'
                        ? Icons.thumb_up
                        : Icons.thumb_down;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text(
                          'Student ID: $studentID',
                          style: TextStyle(color: attendanceColor),
                        ),
                        subtitle: Text(
                          'Attendance: $attendanceStatus',
                          style: TextStyle(color: attendanceColor),
                        ),
                        trailing: Icon(
                          attendanceIcon,
                          color: attendanceColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
