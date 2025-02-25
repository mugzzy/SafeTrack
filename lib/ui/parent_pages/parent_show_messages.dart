import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParentShowMessagesPage extends StatefulWidget {
  final String studentId;
  final String username;

  const ParentShowMessagesPage({
    Key? key,
    required this.studentId,
    required this.username,
  }) : super(key: key);

  @override
  _ParentShowMessagesPageState createState() => _ParentShowMessagesPageState();
}

class _ParentShowMessagesPageState extends State<ParentShowMessagesPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasNewMessages = false;

  Future<List<Map<String, dynamic>>> fetchMessages(String studentId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user is logged in!");
      return [];
    }

    final parentId = user.uid;
    print("Logged-in user ID (parentId): $parentId");

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('student_notifications')
          .where('studentId', isEqualTo: studentId)
          .get();

      print(
          "Total documents in student_notifications: ${querySnapshot.docs.length}");

      List<Map<String, dynamic>> messages = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print("Document ID: ${doc.id}");
        print("Document Data: $data");

        final message = data['message'];
        final timestamp = data['timestamp'];
        final studentId = data['studentId'];
        final userEmail = data['userEmail'];

        messages.add({
          'id': doc.id, // Include document ID to update seen status later
          'message': message ?? 'No message available',
          'timestamp': timestamp,
          'studentId': studentId ?? 'Unknown Student ID',
          'userEmail': userEmail ?? 'Unknown Email',
        });
      }

      if (messages.isEmpty) {
        print("No messages found for the user.");
      } else {
        print("Messages found: ${messages.length}");
      }

      return messages;
    } catch (e) {
      print("Error fetching messages: $e");
      throw Exception("Error fetching messages: $e");
    }
  }

  /// Marks all messages as "seen" for the logged-in user
  Future<void> markMessagesAsSeen(String studentId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user is logged in!");
      return;
    }

    final parentId = user.uid;

    try {
      // Fetch all relevant messages for the given student
      final querySnapshot = await FirebaseFirestore.instance
          .collection('student_notifications')
          .where('studentId', isEqualTo: studentId)
          .get();

      for (var doc in querySnapshot.docs) {
        final recipients = List<Map<String, dynamic>>.from(doc['recipients']);

        // Update the status for the logged-in parent's entry
        final updatedRecipients = recipients.map((recipient) {
          if (recipient['parentId'] == parentId) {
            return {
              ...recipient,
              'status': 'seen',
            };
          }
          return recipient;
        }).toList();

        // Save the updated recipients array back to Firestore
        await FirebaseFirestore.instance
            .collection('student_notifications')
            .doc(doc.id)
            .update({'recipients': updatedRecipients});
      }

      print("All messages marked as seen for parentId: $parentId");
    } catch (e) {
      print("Error updating message status: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent) {
        // Call markMessagesAsSeen when scrolled to the bottom
        markMessagesAsSeen(widget.studentId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.username),
            if (_hasNewMessages)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.notifications, color: Colors.red),
              ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMessages(widget.studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            debugPrint('Error in FutureBuilder: ${snapshot.error}');
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No messages from this student.'));
          }

          final messages = snapshot.data!;

          final Map<String, List<Map<String, dynamic>>> groupedMessages = {};
          for (var message in messages) {
            final timestamp = message['timestamp'] as Timestamp;
            final date = DateFormat('MMMM d, yyyy').format(timestamp.toDate());
            groupedMessages[date] = [
              ...(groupedMessages[date] ?? []),
              message,
            ];
          }

          final groupedMessagesList = groupedMessages.entries.toList();
          groupedMessagesList.sort((a, b) {
            final dateA = DateFormat('MMMM d, yyyy').parse(a.key);
            final dateB = DateFormat('MMMM d, yyyy').parse(b.key);
            return dateA.compareTo(dateB);
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return ListView.builder(
            controller: _scrollController,
            itemCount: groupedMessagesList.length,
            itemBuilder: (context, index) {
              final date = groupedMessagesList[index].key;
              final dateMessages = groupedMessagesList[index].value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Divider(thickness: 1, color: Colors.grey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            date,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Expanded(
                            child: Divider(thickness: 1, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ...dateMessages.map((message) {
                    final timestamp = message['timestamp'] as Timestamp;
                    final time = DateFormat('h:mm a')
                        .format(timestamp.toDate())
                        .toLowerCase();
                    final messageText =
                        message['message'] ?? 'No message content';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              time,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Card(
                          color: Colors.blue.shade100,
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 24),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageText,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    DateFormat('MMMM d, yyyy h:mm a')
                                        .format(timestamp.toDate())
                                        .toLowerCase(),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
