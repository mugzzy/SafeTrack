import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class EarlyLateReportPage extends StatefulWidget {
  const EarlyLateReportPage({super.key});

  @override
  _EarlyLateReportPageState createState() => _EarlyLateReportPageState();
}

class _EarlyLateReportPageState extends State<EarlyLateReportPage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> _events = [];
  String? _selectedEvent;
  List<Map<String, dynamic>> _studentAttendanceData = [];
  Map<String, String> _studentIDs = {}; // Store studentUID to studentID mapping

  // Fetch events for the selected date
  Future<void> _fetchEventsForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('startTime', isGreaterThanOrEqualTo: date)
          .where('startTime', isLessThan: date.add(const Duration(days: 1)))
          .get();

      List<String> eventNames =
          eventSnapshot.docs.map((doc) => doc['eventName'] as String).toList();

      setState(() {
        _events = eventNames.isEmpty ? ["No events"] : eventNames;
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
        _isLoading = false;
      });
    }
  }

  // Fetch student attendance data for the selected event
  Future<void> _fetchStudentAttendanceData(String eventName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .where('eventName', isEqualTo: eventName)
          .get()
          .then((snapshot) => snapshot.docs.first);

      DateTime eventStartTime = (eventDoc['startTime'] as Timestamp).toDate();
      List<dynamic> studentIds = eventDoc['studentIds'] ?? [];

      List<Map<String, dynamic>> attendanceData = [];

      for (String studentId in studentIds) {
        DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
            .collection('attendance')
            .doc(dateString)
            .collection(eventName)
            .doc(studentId)
            .get();

        String status = 'Absent';
        String timeIn = 'N/A';

        if (attendanceDoc.exists) {
          var data = attendanceDoc.data() as Map<String, dynamic>;
          timeIn = data['timeIn'] ?? 'N/A';
          DateTime timeInDateTime = DateFormat.jm().parse(timeIn);

          if (timeInDateTime.isBefore(eventStartTime.add(Duration(hours: 1)))) {
            status = 'Early';
          } else {
            status = 'Late';
          }
        }

        // Fetch studentID for each studentUID
        String studentID = await _getStudentID(studentId);

        attendanceData.add({
          'studentId': studentId,
          'studentID': studentID, // Add studentID to the data
          'timeIn': timeIn,
          'status': status,
        });
      }

      setState(() {
        _studentAttendanceData = attendanceData;
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

  // Fetch studentID from the users collection using studentUID
  Future<String> _getStudentID(String studentId) async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();
      if (studentDoc.exists) {
        var studentData = studentDoc.data() as Map<String, dynamic>;
        return studentData['studentID'] ?? 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
    return 'Unknown';
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
        title: const Text('Early & Late Report'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Date',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedEvent,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _events.map((String event) {
                        return DropdownMenuItem<String>(
                          value: event,
                          child: Flexible(
                            child: Text(
                              event,
                              overflow: TextOverflow
                                  .ellipsis, // Ensures text truncates with "..."
                              maxLines: 1, // Ensures only one line is displayed
                              softWrap:
                                  false, // Prevents wrapping to a new line
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedEvent = newValue;
                        });
                        if (newValue != null) {
                          _fetchStudentAttendanceData(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_isLoading)
              Center(
                child: SpinKitChasingDots(
                  color: Colors.blueAccent,
                  size: 50.0,
                ),
              ),
            if (!_isLoading && _studentAttendanceData.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    _buildChart(),
                    const SizedBox(height: 16.0),
                    _buildStudentList(),
                  ],
                ),
              ),
            if (!_isLoading && _studentAttendanceData.isEmpty)
              const Center(
                child: Text('No attendance data found for the selected event.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    int earlyCount = _studentAttendanceData
        .where((data) => data['status'] == 'Early')
        .length;
    int lateCount =
        _studentAttendanceData.where((data) => data['status'] == 'Late').length;
    int absentCount = _studentAttendanceData
        .where((data) => data['status'] == 'Absent')
        .length;

    return SizedBox(
      height: 200.0,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: earlyCount.toDouble(),
              title: 'Early',
              color: Colors.green,
            ),
            PieChartSectionData(
              value: lateCount.toDouble(),
              title: 'Late',
              color: Colors.red,
            ),
            PieChartSectionData(
              value: absentCount.toDouble(),
              title: 'Absent',
              color: Colors.grey,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _studentAttendanceData.length,
        itemBuilder: (context, index) {
          var studentData = _studentAttendanceData[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('Student ID: ${studentData['studentID']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time In: ${studentData['timeIn']}'),
                  Text('Status: ${studentData['status']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
