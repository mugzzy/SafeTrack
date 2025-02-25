import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.black54,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profile'),

        /// **Message Icon with Unread Indicator**
        BottomNavigationBarItem(
          icon: StreamBuilder<QuerySnapshot>(
            stream: _getUnseenMessagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Icon(Icons.message); // Default icon while loading
              }

              if (snapshot.hasError) {
                return const Icon(
                    Icons.message); // Default icon if an error occurs
              }

              // Filter unseen messages for the current user
              final unseenMessages = snapshot.data?.docs.where((doc) {
                final recipients =
                    List<Map<String, dynamic>>.from(doc['recipients'] ?? []);
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                return recipients.any((recipient) =>
                    recipient['parentId'] == currentUserId &&
                    recipient['status'] == 'unseen');
              }).toList();

              // Show badge only if there are unseen messages
              if (unseenMessages != null && unseenMessages.isNotEmpty) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.message, size: 30), // Base message icon
                    Positioned(
                      right: -4, // Position the badge slightly outside the icon
                      top: -4, // Align the badge at the top-right
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unseenMessages.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const Icon(Icons.message); // Default message icon
            },
          ),
          label: 'Message',
        ),

        const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz), label: 'More'),
      ],
      onTap: onTap,
    );
  }

  /// Stream to listen for unseen messages for the current user
  Stream<QuerySnapshot> _getUnseenMessagesStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('student_notifications')
        .where('recipients', arrayContains: {
      'parentId': currentUserId,
      'status': 'unseen',
    }).snapshots();
  }
}
