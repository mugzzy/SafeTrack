import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Welcome Message
            _buildWelcomeMessage(),
            const SizedBox(height: 16.0),

            // FAQs Section
            _buildSectionTitle("Frequently Asked Questions (FAQs)"),
            const SizedBox(height: 8.0),
            _buildFAQItem(
              "How do I create an account?",
              "Open the SafeTrack app, tap 'Sign Up', fill in the required information, and verify your account via the confirmation email.",
            ),
            _buildFAQItem(
              "How do I share my location with others?",
              "Go to your profile > Account Settings > Location Sharing, and select who can view your location.",
            ),
            _buildFAQItem(
              "How do I send an emergency notification?",
              "Tap the 'Emergency' button in the app, select or type a message, and tap 'Send' to notify parents or event personnel.",
            ),
            const SizedBox(height: 16.0),

            // Contact Us Section
            _buildSectionTitle("Need Help? Contact Us!"),
            const SizedBox(height: 8.0),
            _buildContactInfo(),
            const SizedBox(height: 16.0),

            // Tutorials Section
            _buildSectionTitle("Tutorials"),
            const SizedBox(height: 8.0),
            const Text(
              "Explore short video tutorials and guides on using SafeTrack's features.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              child: const Text(
                "Link to tutorials or embedded videos here",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline),
              ),
              onTap: () =>
                  _launchURL('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome to SafeTrack!",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 4.0),
          Text(
            "SafeTrack is designed to help Assumption College of Davao manage student safety and attendance during off-campus events. We use GPS technology, geofencing, and the Kalman filter algorithm to provide accurate and reliable location tracking.",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(answer, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Email: support@safetrack.com",
              style: TextStyle(fontSize: 16)),
          SizedBox(height: 4.0),
          Text("Phone: +123 456 7890", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4.0),
          Text("Support Form: [Link to Support Form]",
              style: TextStyle(fontSize: 16, color: Colors.blue)),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
