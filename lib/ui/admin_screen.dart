import 'package:flutter/material.dart';

import 'admin_pages/admin_dashboard.dart';
import 'admin_pages/admin_navbar.dart';
import 'admin_pages/audit_logs_page.dart';
import 'admin_pages/events_page.dart';
import 'admin_pages/manage_users_page.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/profile.jpg'), // Add a profile image
                ),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The_Rock',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Super Admin'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
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
