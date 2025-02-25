import 'package:capstone_1/ui/student_pages/student_profile/Attendance_report_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceReportLogs extends StatefulWidget {
  const AttendanceReportLogs({super.key});

  @override
  State<AttendanceReportLogs> createState() => _AttendanceReportLogsState();
}

class _AttendanceReportLogsState extends State<AttendanceReportLogs> {
  String? selectedYear;
  List<String> years = [];
  final int _itemsPerPage = 4; // Number of items per page
  int _currentPage = 0;
  late Future<List<Map<String, dynamic>>> _eventsFuture = Future.value([]);
  int presentCount = 0;
  int lateCount = 0;
  int absentCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeYears();
  }

  void _initializeYears() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('studentIds', arrayContains: currentUserId)
        .get();

    final eventYears = eventsSnapshot.docs.map((doc) {
      final Timestamp startTime = doc['startTime'];
      return DateFormat('yyyy').format(startTime.toDate());
    }).toSet();

    setState(() {
      years = eventYears.toList()..sort();
      if (years.isNotEmpty) {
        selectedYear = years.first;
        _eventsFuture = _fetchStudentEvents();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchStudentEvents() async {
    if (selectedYear == null) return [];

    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('studentIds', arrayContains: currentUserId)
        .get();

    List<Map<String, dynamic>> eventData = [];
    presentCount = 0;
    lateCount = 0;
    absentCount = 0;

    for (var doc in eventsSnapshot.docs) {
      final Timestamp startTime = doc['startTime'];
      if (DateFormat('yyyy').format(startTime.toDate()) == selectedYear) {
        DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
            .collection('attendance')
            .doc(DateFormat('yyyy-MM-dd').format(startTime.toDate()))
            .collection(doc['eventName'])
            .doc(currentUserId)
            .get();

        String status = 'Absent';
        Color statusColor = Colors.red;
        IconData statusIcon = Icons.thumb_down;

        if (attendanceDoc.exists) {
          var data = attendanceDoc.data() as Map<String, dynamic>;
          String timeIn = data['timeIn'] ?? 'N/A';
          DateTime timeInDateTime = DateFormat.jm().parse(timeIn);
          DateTime eventStartTime = startTime.toDate();

          if (timeInDateTime.isBefore(eventStartTime.add(Duration(hours: 1)))) {
            status = 'Early';
            statusColor = Colors.green;
            statusIcon = Icons.thumb_up;
            presentCount++;
          } else {
            status = 'Late';
            statusColor = Colors.orange;
            statusIcon = Icons.thumb_up;
            lateCount++;
          }
        } else {
          absentCount++;
        }

        eventData.add({
          'eventName': doc['eventName'],
          'createdAt': DateFormat('MM/dd/yyyy').format(startTime.toDate()),
          'status': status,
          'statusColor': statusColor,
          'statusIcon': statusIcon,
        });
      }
    }

    return eventData;
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
        title: const Text('Attendance Report Logs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: 'Select Year',
                border: OutlineInputBorder(),
              ),
              items: years.map((year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  _eventsFuture = _fetchStudentEvents();
                  _currentPage = 0; // Reset to first page
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$presentCount Present | $lateCount Late | $absentCount Absent',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.pie_chart),
                  color: Colors.blue,
                  iconSize: 30.0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceReportChart(
                          presentCount: presentCount,
                          lateCount: lateCount,
                          absentCount: absentCount,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading events.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No events to display.'));
                }

                final events = snapshot.data!;
                int totalPages = (events.length / _itemsPerPage).ceil();
                List<Map<String, dynamic>> visibleEvents = events
                    .skip(_currentPage * _itemsPerPage)
                    .take(_itemsPerPage)
                    .toList();

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: visibleEvents.length,
                        itemBuilder: (context, index) {
                          final event = visibleEvents[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Card(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Event: ${event['eventName']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Meeting: ${event['createdAt']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 8.0),
                                        Row(
                                          children: [
                                            Text(
                                              'Status: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            Text(
                                              event['status'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      color:
                                                          event['statusColor']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      event['statusIcon'],
                                      color: event['statusColor'],
                                      size: 40.0,
                                    ),
                                  ],
                                ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Icon(Icons.arrow_left),
                        ),
                        const SizedBox(width: 8), // Space between buttons
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
                          onPressed:
                              _currentPage < totalPages - 1 ? _nextPage : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Icon(Icons.arrow_right),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
