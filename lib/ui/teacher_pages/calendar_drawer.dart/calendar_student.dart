import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalendarInvitedPage extends StatefulWidget {
  final String eventId;

  const CalendarInvitedPage({super.key, required this.eventId});

  @override
  _CalendarInvitedPageState createState() => _CalendarInvitedPageState();
}

class _CalendarInvitedPageState extends State<CalendarInvitedPage> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _invitedStudents = [];
  final int _limit =
      5; // Number of students to load per page (5 students per page)
  DocumentSnapshot? _lastDocument; // Track the last fetched document
  DocumentSnapshot?
      _firstDocument; // Track the first document for the previous page
  bool _hasMore = true; // Flag to check if more data exists
  bool _hasPrevious = false; // Flag to check if there is previous data

  Future<void> _fetchInvitedStudents(
      {bool isInitialLoad = false, bool isNextPage = true}) async {
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
        _invitedStudents.clear();
        _lastDocument = null;
        _firstDocument = null;
        _hasMore = true;
        _hasPrevious = false;
      });
    } else {
      if (!_hasMore || _isLoadingMore) return; // Prevent duplicate loads
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      // Fetch the event data
      final eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      final eventData = eventSnapshot.data() as Map<String, dynamic>;
      final List<String> studentIds =
          List<String>.from(eventData['studentIds'] ?? []);

      if (studentIds.isNotEmpty) {
        // Fetch paginated student details
        Query query = FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: studentIds)
            .limit(_limit);

        if (isNextPage && _lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        } else if (!isNextPage && _firstDocument != null) {
          query = query.endBeforeDocument(_firstDocument!);
        }

        final studentsSnapshot = await query.get();

        if (studentsSnapshot.docs.isNotEmpty) {
          setState(() {
            _invitedStudents = studentsSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>?;

              return {
                'id': doc.id,
                'firstname': data?['firstname'] ?? '',
                'lastname': data?['lastname'] ?? '',
                'studentID': data?['studentID'] ?? 'N/A',
                'profilePicture': data?['profilePicture'] ?? '',
              };
            }).toList();

            // Update the last and first document based on the direction of pagination
            _lastDocument = studentsSnapshot.docs.last;
            _firstDocument = studentsSnapshot.docs.first;

            // Check if more data exists for next page
            _hasMore = studentsSnapshot.docs.length == _limit;
            _hasPrevious = true;
          });
        } else {
          setState(() {
            _hasMore = false; // No more data to fetch
          });
        }
      } else {
        setState(() {
          _hasMore = false; // No students available
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInvitedStudents(isInitialLoad: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        // title: const Text('Invited Students'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _invitedStudents.isEmpty
                      ? const Center(
                          child: Text(
                            'No students invited yet.',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _invitedStudents.length,
                          itemBuilder: (context, index) {
                            final student = _invitedStudents[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 5.0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Circle Avatar for Profile Picture
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                        student['profilePicture'].isNotEmpty
                                            ? NetworkImage(
                                                student['profilePicture'])
                                            : null,
                                    child: student['profilePicture'].isEmpty
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  // Student Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${student['firstname']} ${student['lastname']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${student['studentID']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoadingMore || !_hasPrevious
                          ? null
                          : () {
                              // Reset and fetch the first page
                              _fetchInvitedStudents(isInitialLoad: true);
                            },
                      child: _isLoadingMore
                          ? const CircularProgressIndicator()
                          : const Text('Previous'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoadingMore || !_hasMore
                          ? null
                          : () {
                              _fetchInvitedStudents(isNextPage: true);
                            },
                      child: _isLoadingMore
                          ? const CircularProgressIndicator()
                          : const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
