import 'package:capstone_1/services/logout_service.dart';
import 'package:capstone_1/ui/More/Profile_pages/help_page.dart';
import 'package:capstone_1/ui/More/Profile_pages/legal_and_policies_page.dart';
import 'package:capstone_1/ui/student_pages/student_more/option_box.dart';
import 'package:capstone_1/ui/student_pages/student_more/profile_header.dart';
import 'package:capstone_1/ui/student_pages/student_more/user_info_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentMorePage extends StatefulWidget {
  const StudentMorePage({super.key});

  @override
  _StudentMorePageState createState() => _StudentMorePageState();
}

class _StudentMorePageState extends State<StudentMorePage> {
  final LogoutService _logoutService = LogoutService(); // Use LogoutService

  Stream<DocumentSnapshot?> _getUserProfileStream() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('More'),
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: _getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found.'));
          }

          var userDoc = snapshot.data!.data() as Map<String, dynamic>;
          String role =
              userDoc['role'] ?? 'student'; // Ensure role is available

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ProfileHeader(
                  profilePictureUrl: userDoc['profilePicture'],
                  fullName: "${userDoc['firstname']} ${userDoc['lastname']}",
                  email: userDoc['email'],
                  onEdit: () => _showUserInfoModal(context, userDoc),
                ),
                const Divider(height: 40, thickness: 1),
                OptionBox(
                  icon: Icons.report_problem,
                  title: 'Report a Problem',
                  onTap: () {
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => ReportProblemPage()));
                  },
                ),
                const SizedBox(height: 10),
                OptionBox(
                  icon: Icons.help,
                  title: 'Help',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HelpPage()));
                  },
                ),
                const SizedBox(height: 10),
                OptionBox(
                  icon: Icons.policy,
                  title: 'Legal & Policies',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LegalAndPoliciesPage(
                                  isRegisterScreen: false,
                                )));
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _logoutService.logout(
                      context, role), // Use the LogoutService
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: Colors.blue,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUserInfoModal(BuildContext context, Map<String, dynamic> userDoc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return UserInfoModal(
          profilePictureUrl: userDoc['profilePicture'],
          fullName: "${userDoc['firstname']} ${userDoc['lastname']}",
          email: userDoc['email'],
          username: userDoc['username'],
          studentID: userDoc['studentID'],
          address: userDoc['address'],
          birthday: userDoc['birthday'],
          onRefresh:
              () {}, // No need to refresh as it will update automatically
        );
      },
    );
  }
}
