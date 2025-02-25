import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserList extends StatelessWidget {
  final Function(String) onUserSelected;

  UserList({required this.onUserSelected});

  Future<List<Map<String, dynamic>>> _getUsersSharingLocation() async {
    List<Map<String, dynamic>> users = [];
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('parentId', isEqualTo: userId)
          .where('status', isEqualTo: 'Accepted')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final childAccountId = data['studentID'] as String?;
        if (childAccountId != null) {
          final childSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('studentID', isEqualTo: childAccountId)
              .limit(1)
              .get();

          if (childSnapshot.docs.isNotEmpty) {
            final childData = childSnapshot.docs.first.data();
            users.add({
              'userId': childSnapshot.docs.first.id,
              'email': childData['email'] ?? 'No Email',
            });
          }
        }
      }
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getUsersSharingLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading users'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No users found sharing location'));
        } else {
          final users = snapshot.data!;
          return Container(
            padding: EdgeInsets.all(16),
            height: 300,
            child: Column(
              children: [
                Text(
                  'Users Sharing Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user['email']),
                        onTap: () {
                          onUserSelected(user['userId']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
