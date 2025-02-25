import 'package:capstone_1/services/auth_service.dart'; // Import AuthService
import 'package:capstone_1/ui/login_screen.dart'; // Import the login screen for navigation
import 'package:flutter/material.dart';

class AdminNavigationDrawer extends StatefulWidget {
  final Function(int) onTap;

  const AdminNavigationDrawer({super.key, required this.onTap});

  @override
  _AdminNavigationDrawerState createState() => _AdminNavigationDrawerState();
}

class _AdminNavigationDrawerState extends State<AdminNavigationDrawer> {
  bool _isOpen = true; // Track whether the drawer is open or closed
  final AuthService _authService =
      AuthService(); // Create an instance of AuthServicep

  void _toggleDrawer() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Animation duration
      curve: Curves.easeInOut, // Animation curve
      width: _isOpen ? 250 : 0, // Width based on visibility
      child: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  'SafeTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                widget.onTap(0);
                _toggleDrawer(); // Close the drawer after selecting
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Users'),
              onTap: () {
                widget.onTap(1);
                _toggleDrawer(); // Close the drawer after selecting
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Events'),
              onTap: () {
                widget.onTap(2);
                _toggleDrawer(); // Close the drawer after selecting
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Audit Logs'),
              onTap: () {
                widget.onTap(3);
                _toggleDrawer(); // Close the drawer after selecting
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                // Use the AuthService's signOut method
                bool success = await _authService.signOut();
                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                } else {
                  // Handle logout failure if needed (e.g., show a snackbar)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logout failed')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
