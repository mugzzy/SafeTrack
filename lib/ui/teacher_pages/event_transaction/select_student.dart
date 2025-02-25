import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectStudentsPage extends StatefulWidget {
  final String eventId;

  const SelectStudentsPage({
    super.key,
    required this.eventId,
  });

  @override
  _SelectStudentsPageState createState() => _SelectStudentsPageState();
}

class _SelectStudentsPageState extends State<SelectStudentsPage> {
  List<String> alreadySelectedStudents = [];
  final List<String> selectedStudents = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAlreadySelectedStudents();
  }

  Future<void> _fetchAlreadySelectedStudents() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        setState(() {
          alreadySelectedStudents =
              List<String>.from(eventDoc.data()!['studentIds'] ?? []);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch existing students: $e')),
      );
    }
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (selectedStudents.contains(studentId)) {
        selectedStudents.remove(studentId);
      } else {
        selectedStudents.add(studentId);
      }
    });
  }

  Future<void> _finalizeSelection() async {
    try {
      // Merge newly selected students with the already selected ones
      final allSelectedStudents = [
        ...alreadySelectedStudents,
        ...selectedStudents
      ];

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({'studentIds': allSelectedStudents});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Students added successfully!')),
      );

      // After finalizing, navigate back to TeacherHome with the correct index
      Navigator.of(context).popUntil(
        (route) => route
            .isFirst, // This ensures the navigation goes back to TeacherScreen
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add students: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Select Students'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Students',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs;

                // Filter the students based on the search query
                final filteredStudents = students.where((student) {
                  final studentName =
                      '${student['firstname']} ${student['lastname']}'
                          .toLowerCase();
                  return studentName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final studentId = student.id;
                    final studentName =
                        '${student['firstname']} ${student['lastname']}';

                    final isAlreadySelected =
                        alreadySelectedStudents.contains(studentId);

                    return ListTile(
                      title: Text(studentName),
                      trailing: Checkbox(
                        value: isAlreadySelected ||
                            selectedStudents.contains(studentId),
                        onChanged: isAlreadySelected
                            ? null // Disable checkbox for already selected students
                            : (_) => _toggleStudentSelection(studentId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _finalizeSelection,
        child: const Icon(Icons.check),
      ),
    );
  }
}
