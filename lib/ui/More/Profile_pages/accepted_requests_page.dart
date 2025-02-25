import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AcceptedRequestsPage extends StatefulWidget {
  const AcceptedRequestsPage({super.key});

  @override
  _AcceptedRequestsPageState createState() => _AcceptedRequestsPageState();
}

class _AcceptedRequestsPageState extends State<AcceptedRequestsPage> {
  String? _studentID;

  @override
  void initState() {
    super.initState();
    _fetchStudentID();
  }

  Future<void> _fetchStudentID() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        setState(() {
          _studentID = userDoc.data()?['studentID'];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch student ID: $e')),
        );
      }
    }
  }

  Future<void> _deleteRequest(String requestId, String parentName) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parent deleted successfully')),
    );
  }

  Future<void> _updateRequestStatus(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'Cancelled'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing stopped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _studentID != null
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('studentID', isEqualTo: _studentID)
                  .where('status', isEqualTo: 'Accepted')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No accepted requests.'));
                }

                final requests = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request =
                        requests[index].data() as Map<String, dynamic>;
                    final requestId = requests[index].id;
                    final parentName = request['parentId'] ?? 'N/A';
                    final email = request['parentemail'] ?? 'N/A';
                    final imageUrl = request['image'] ?? '';
                    final username = request['parentusername'] ?? 'N/A';

                    return Dismissible(
                      key: Key(requestId),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await _confirmDeleteDialog(parentName);
                      },
                      onDismissed: (direction) {
                        _deleteRequest(requestId, parentName);
                      },
                      child: RequestCard(
                        parentName: parentName,
                        email: email,
                        imageUrl: imageUrl,
                        username: username,
                        timestamp:
                            (request['timestamp'] as Timestamp?)?.toDate(),
                        requestId: requestId,
                        onStopSharing: () => _updateRequestStatus(requestId),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Future<bool?> _confirmDeleteDialog(String parentName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete "$parentName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}

class RequestCard extends StatelessWidget {
  final String parentName;
  final String email;
  final String imageUrl;
  final String username;
  final DateTime? timestamp;
  final String requestId;
  final VoidCallback onStopSharing;

  const RequestCard({
    super.key,
    required this.parentName,
    required this.email,
    required this.imageUrl,
    required this.username,
    this.timestamp,
    required this.requestId,
    required this.onStopSharing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          ' $username',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(' $email'),
            Text('Accepted on: ${timestamp?.toLocal() ?? DateTime.now()}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'stop_sharing') {
              onStopSharing();
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'stop_sharing',
                child: Row(
                  children: const [
                    Icon(Icons.stop, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Stop Sharing Location'),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }
}
