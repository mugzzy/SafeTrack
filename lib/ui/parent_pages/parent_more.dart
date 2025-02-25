import 'package:capstone_1/services/logout_service.dart'; // Import the logout service
import 'package:capstone_1/ui/More/Profile_pages/help_page.dart';
import 'package:capstone_1/ui/More/Profile_pages/legal_and_policies_page.dart';
import 'package:capstone_1/ui/More/Profile_pages/profile_avatar_more.dart';
import 'package:capstone_1/ui/More/Profile_pages/see_students_location_page.dart';
import 'package:flutter/material.dart';

class ParentMorePage extends StatefulWidget {
  const ParentMorePage({super.key});

  @override
  _ParentMorePageState createState() => _ParentMorePageState();
}

class _ParentMorePageState extends State<ParentMorePage> {
  final LogoutService _logoutService =
      LogoutService(); // Initialize the logout service

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Section
            ProfileAvatarMore(),
            const SizedBox(height: 20),

            // Sections
            _buildSection(
              screenWidth,
              'See Students Location',
              'List of people you can view their location',
              Icons.location_on,
              () {
                // Add functionality for Manage Location Sharing
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AcceptedStudentsList()),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildSection(
              screenWidth,
              'Legal & Policies',
              'Read our privacy policy and terms.',
              Icons.policy,
              () {
                // Navigate to the LegalAndPoliciesPage when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LegalAndPoliciesPage(
                      isRegisterScreen: false,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildSection(
              screenWidth,
              'Help',
              'Need assistance? Get help with SafeTrack.',
              Icons.help,
              () {
                // Navigate to the HelpPage when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildSection(
              screenWidth,
              'Report a problem',
              'If you encounter problems kindly report it to us!',
              Icons.report_problem,
              () {
                // Navigate to the ReportProblemPage when tapped
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ReportProblemPage(),
                //   ),
                // );
              },
            ),
            const SizedBox(height: 20),
            // Logout Section
            ElevatedButton.icon(
              onPressed: () => _logoutService.logout(
                  context, 'parent'), // Use the LogoutService
              icon: const Icon(Icons.logout, color: Colors.white),
              label:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                backgroundColor: Colors.blue,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(double width, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
