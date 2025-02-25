import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalendarAttendancePage extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String eventDate;

  const CalendarAttendancePage({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
  });

  @override
  _CalendarAttendancePageState createState() => _CalendarAttendancePageState();
}

class _CalendarAttendancePageState extends State<CalendarAttendancePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _attendanceFuture;
  final int _itemsPerPage = 5; // Number of items per page
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _fetchAttendanceData();
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceData() async {
    List<Map<String, dynamic>> attendanceRecords = [];
    try {
      DocumentSnapshot eventDoc =
          await _db.collection('events').doc(widget.eventId).get();

      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        List<String> studentIds =
            List<String>.from(eventData['studentIds'] ?? []);

        for (String studentId in studentIds) {
          DocumentSnapshot studentDoc =
              await _db.collection('users').doc(studentId).get();
          String studentID = 'Unknown';
          if (studentDoc.exists) {
            var studentData = studentDoc.data() as Map<String, dynamic>;
            studentID = studentData['studentID'] ?? 'Unknown';
          }

          DocumentSnapshot attendanceDoc = await _db
              .collection('attendance')
              .doc(widget.eventDate)
              .collection(widget.eventName)
              .doc(studentId)
              .get();

          Map<String, dynamic> record = {
            'studentUid': studentId,
            'studentId': studentID,
            'timeIn': '',
            'timeOut': '', // Add timeOut field here
            'geoStatus': '',
            'teacherAttendance': 'Blank',
            'PhoneIPAddress': '',
            'deviceId': '',
            'osVersion': '',
            'deviceModel': '',
          };

          if (attendanceDoc.exists) {
            var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
            record['timeIn'] = attendanceData['timeIn'] ?? 'N/A';
            record['timeOut'] =
                attendanceData['timeOut'] ?? 'N/A'; // Fetch timeOut data
            record['geoStatus'] = attendanceData['geoStatus'] ?? 'N/A';
            record['teacherAttendance'] =
                attendanceData['teacherAttendance'] ?? 'Blank';
            record['PhoneIPAddress'] =
                attendanceData['PhoneIPAddress'] ?? 'N/A';
            record['deviceId'] = attendanceData['deviceId'] ?? 'N/A';
            record['osVersion'] = attendanceData['osVersion'] ?? 'N/A';
            record['deviceModel'] = attendanceData['deviceModel'] ?? 'N/A';
          }

          attendanceRecords.add(record);
        }
      }

      QuerySnapshot geofenceSnapshot = await _db
          .collection('attendance')
          .doc(widget.eventDate)
          .collection(widget.eventName)
          .where('geoStatus', isEqualTo: 'Inside Geofence')
          .get();

      for (var doc in geofenceSnapshot.docs) {
        var geofenceData = doc.data() as Map<String, dynamic>;
        var studentId = doc.id;

        bool exists = attendanceRecords.any((record) =>
            record['studentUid'] == studentId &&
            record['geoStatus'] == 'Inside Geofence');

        if (!exists) {
          DocumentSnapshot studentDoc =
              await _db.collection('users').doc(studentId).get();
          String studentID = 'Unknown';
          if (studentDoc.exists) {
            var studentData = studentDoc.data() as Map<String, dynamic>;
            studentID = studentData['studentID'] ?? 'Unknown';
          }

          geofenceData['studentUid'] = studentId;
          geofenceData['studentId'] = studentID;
          attendanceRecords.add(geofenceData);
        }
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
    }
    return attendanceRecords;
  }

  Future<void> _updateAttendance(
      String studentUid, String attendanceStatus) async {
    try {
      await _db
          .collection('attendance')
          .doc(widget.eventDate)
          .collection(widget.eventName)
          .doc(studentUid)
          .set({
        'teacherAttendance': attendanceStatus,
      }, SetOptions(merge: true));
      print('Updated attendance for $studentUid to $attendanceStatus');
    } catch (e) {
      print('Error updating attendance: $e');
    }
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _prevPage() {
    setState(() {
      _currentPage--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.eventName),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          List<Map<String, dynamic>> attendanceRecords = snapshot.data ?? [];
          if (attendanceRecords.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
            );
          }

          int totalPages = (attendanceRecords.length / _itemsPerPage).ceil();
          List<Map<String, dynamic>> visibleRecords = attendanceRecords
              .skip(_currentPage * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: visibleRecords.length,
                  itemBuilder: (context, index) {
                    final record = visibleRecords[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Student ID: ${record['studentId']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                DropdownButton<String>(
                                  value: record['teacherAttendance'] != 'Blank'
                                      ? record['teacherAttendance']
                                      : null,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Present',
                                      child: Text(
                                        'Present',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Absent',
                                      child: Text(
                                        'Absent',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        record['teacherAttendance'] = value;
                                      });
                                      _updateAttendance(
                                          record['studentUid'], value);
                                    }
                                  },
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'IP Address: ${record['PhoneIPAddress'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Device: ${record['deviceModel'] ?? 'Unknown'} | OS: ${record['osVersion'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time In: ${record['timeIn']} | Time Out: ${record['timeOut'] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Geo Status: ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  TextSpan(
                                    text: '${record['geoStatus'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _currentPage > 0 ? _prevPage : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Icon(Icons.arrow_left),
                  ),
                  const SizedBox(width: 8), // Space between buttons
                  // Page numbers (compact and bold)
                  for (int i = 0; i < totalPages; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage = i;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPage == i
                              ? Colors.blue
                              : Colors.grey, // Highlight current page
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(4), // Square button
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8), // Space between buttons
                  ElevatedButton(
                    onPressed: _currentPage < totalPages - 1 ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Icon(Icons.arrow_right),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}
