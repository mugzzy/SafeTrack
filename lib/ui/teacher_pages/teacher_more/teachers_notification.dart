import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeachersNotificationPage extends StatelessWidget {
  const TeachersNotificationPage({super.key});

  Future<Map<String, List<Map<String, dynamic>>>> fetchNotifications() async {
    // Fetch all events from Firestore
    QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .get();

    // Prepare a map to track user details by UID
    Map<String, Map<String, dynamic>> userCache = {};

    // Group notifications by date
    Map<String, List<Map<String, dynamic>>> notificationsByDate = {};

    for (var doc in eventSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp).toDate();

      // Format date as string (e.g., '24/11/2024')
      final dateKey = "${createdAt.day}/${createdAt.month}/${createdAt.year}";

      // Fetch teacher details from users collection (if not cached)
      final teacherId = data['teacherId'];
      if (!userCache.containsKey(teacherId)) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(teacherId)
            .get();
        if (userDoc.exists) {
          userCache[teacherId] = userDoc.data()!;
        } else {
          userCache[teacherId] = {
            'firstname': 'Unknown',
            'lastname': 'User',
          };
        }
      }

      // Add event details to the grouped map
      final teacherData = userCache[teacherId]!;
      if (!notificationsByDate.containsKey(dateKey)) {
        notificationsByDate[dateKey] = [];
      }
      notificationsByDate[dateKey]!.add({
        'eventName': data['eventName'],
        'createdBy': "${teacherData['firstname']} ${teacherData['lastname']}",
        'createdAt': createdAt,
      });
    }

    return notificationsByDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notificationsByDate = snapshot.data!;

          return ListView.builder(
            itemCount: notificationsByDate.keys.length,
            itemBuilder: (context, index) {
              final dateKey = notificationsByDate.keys.toList()[index];
              final events = notificationsByDate[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Event Notifications
                  ...events.map((event) => ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.event),
                        ),
                        title: Text.rich(
                          TextSpan(
                            text: ":",
                            children: <TextSpan>[
                              TextSpan(
                                text: " ${event['createdBy']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    " created an event (${event['eventName']})",
                              ),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          "Created at: ${event['createdAt']}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
