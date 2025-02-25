import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/event_model.dart';

class EventUpdates extends StatefulWidget {
  final EventModel event;

  EventUpdates({required this.event});

  @override
  _EventUpdatesState createState() => _EventUpdatesState();
}

class _EventUpdatesState extends State<EventUpdates> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Updates', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('event_notifications')
            .doc(widget.event.eventId)
            .collection('event_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No updates available.'));
          }

          final updates = snapshot.data!.docs;

          return Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: updates.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                var update = updates[index].data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  leading: Icon(Icons.update, color: Colors.blueAccent),
                  title: Text(update['email'] ?? 'Summary',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Expanded(child: Text(update['update'])),
                      Text(
                        formatTimestamp(update['timestamp']),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('MM/dd/yyyy hh:mm a').format(timestamp.toDate());
  }
}
