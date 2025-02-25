import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard.dart';
import 'admin_navbar.dart';
import 'audit_logs_page.dart';
import 'events_page.dart';
import 'manage_users_page.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String? email;
  String? role;
  String? studentID;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData(); // Fetch admin data when the page is loaded
  }

  // Fetch the admin data from Firestore
  Future<void> _fetchAdminData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        email = userDoc.data()?['email'];
        role = userDoc.data()?['role'];
        studentID =
            userDoc.data()?['studentID']; // Assuming you store it as studentID
        isLoading = false; // Set loading to false once data is fetched
      });
    }
  }

  int _currentIndex = 0;
  bool _isDrawerVisible = true;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const ManageUsersPage(),
    const EventsPage(),
     const AuditLogsPage(),
  ];

  void _onDrawerTap(int index) {
    setState(() {
      _currentIndex = index;
      _isDrawerVisible = true;
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerVisible = !_isDrawerVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isDrawerVisible ? Icons.arrow_back : Icons.menu),
            onPressed: _toggleDrawer,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Admin Profile Picture
                const CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/profile.jpg'), // Add a profile image
                ),
                const SizedBox(width: 8),
                // Display Email and Role + Student ID
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${role ?? 'N/A'}  ${studentID ?? 'N/A'}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading // Check if data is still loading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Row(
              children: [
                if (_isDrawerVisible)
                  Expanded(
                    child: AdminNavigationDrawer(onTap: _onDrawerTap),
                  ),
                Expanded(
                  flex: 5,
                  child: _pages[_currentIndex],
                ),
              ],
            ),
    );
  }
}
