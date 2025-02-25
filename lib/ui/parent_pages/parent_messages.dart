import 'package:capstone_1/ui/parent_pages/parent_show_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParentMessagesPage extends StatefulWidget {
  const ParentMessagesPage({Key? key}) : super(key: key);

  @override
  _ParentMessagesPageState createState() => _ParentMessagesPageState();
}

class _ParentMessagesPageState extends State<ParentMessagesPage> {
  Future<void> _markMessageAsRead(String studentId, String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final parentId = user.uid;
    final docRef = FirebaseFirestore.instance
        .collection('student_notifications')
        .doc(messageId);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data() as Map<String, dynamic>;
      final recipients =
          List<Map<String, dynamic>>.from(data['recipients'] ?? []);

      final recipientIndex = recipients.indexWhere((recipient) =>
          recipient['parentId'] == parentId && recipient['status'] == 'unseen');

      if (recipientIndex != -1) {
        recipients[recipientIndex]['status'] = 'seen';
        await docRef.update({'recipients': recipients});
      }
    } catch (e) {
      print("Error marking message as read: $e");
    }
  }

  List<Map<String, dynamic>> _processSnapshot(QuerySnapshot snapshot) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final parentId = user.uid;
    Map<String, Map<String, dynamic>> latestMessages = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final recipients =
          List<Map<String, dynamic>>.from(data['recipients'] ?? []);

      // Check if the current parent is a recipient
      final isRecipient =
          recipients.any((recipient) => recipient['parentId'] == parentId);
      if (!isRecipient) continue;

      final message = data['message'];
      final timestamp = data['timestamp'];
      final studentId = data['studentId'];
      final userEmail = data['userEmail'];

      if (!latestMessages.containsKey(studentId) ||
          (timestamp as Timestamp).toDate().isAfter(
              (latestMessages[studentId]!['timestamp'] as Timestamp)
                  .toDate())) {
        latestMessages[studentId] = {
          'message': message ?? 'No message available',
          'timestamp': timestamp,
          'studentId': studentId ?? 'Unknown Student ID',
          'userEmail': userEmail ?? 'Unknown Email',
          'messageId': doc.id,
          'isNewMessage': recipients.any((recipient) =>
              recipient['parentId'] == parentId &&
              recipient['status'] == 'unseen'),
        };
      }
    }

    return latestMessages.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Notifications', style: TextStyle(fontSize: 20)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('student_notifications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No messages yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          final messages = _processSnapshot(snapshot.data!);
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return StudentMessageCard(
                student: {
                  'username': message['userEmail'] ?? 'Unknown Student',
                  'latestMessage': message['message'] ?? 'No message available',
                  'timestamp': message['timestamp'],
                },
                isNewMessage: message['isNewMessage'] ?? false,
                onTap: () {
                  _markMessageAsRead(
                      message['studentId'], message['messageId']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentShowMessagesPage(
                        studentId: message['studentId'],
                        username: message['userEmail'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class StudentMessageCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isNewMessage;
  final VoidCallback onTap;

  const StudentMessageCard({
    Key? key,
    required this.student,
    required this.isNewMessage,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = student['timestamp'] as Timestamp?;
    final formattedTime = timestamp != null
        ? DateFormat('MMMM d, yyyy h:mm a').format(timestamp.toDate())
        : 'No timestamp';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: CircleAvatar(
              backgroundColor: isNewMessage ? Colors.blue : Colors.grey[300],
              child: Text(
                student['username'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              student['username'] ?? 'Unknown Student',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isNewMessage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['latestMessage'] ?? 'No message available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: isNewMessage
                ? const Icon(Icons.notifications_active, color: Colors.red)
                : null,
          ),
        ),
      ),
    );
  }
}
