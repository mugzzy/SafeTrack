import 'package:flutter/material.dart';

class LegalAndPoliciesPage extends StatelessWidget {
  const LegalAndPoliciesPage({
    super.key,
    required bool isRegisterScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal and Privacy Policies',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 1.0,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              title: 'SafeTrack Data Privacy Policy',
              content: [
                _buildParagraph(
                  'SafeTrack is committed to protecting your privacy and ensuring the security of your personal information. '
                  'This Data Privacy Policy explains how we collect, use, disclose, and protect your data when you use our app.',
                ),
                _buildSubSection(
                  title: 'Information We Collect',
                  bulletPoints: [
                    'User account information (name, email, password, phone number)',
                    'Location data (GPS coordinates, location history)',
                    'Event data (event names, dates, locations)',
                    'Emergency contact information',
                  ],
                ),
                _buildSubSection(
                  title: 'How We Use Your Information',
                  bulletPoints: [
                    'To create and manage user accounts',
                    'To provide location tracking and geofencing services',
                    'To send notifications and alerts',
                    'To improve the SafeTrack app and services',
                  ],
                ),
                _buildSubSection(
                  title: 'Sharing Your Information',
                  bulletPoints: [
                    'With school personnel (teachers, administrators) for event management and student safety',
                    'With parents for monitoring their child\'s location',
                    'With service providers (e.g., Google Maps API) for location services',
                  ],
                ),
                _buildSubSection(
                  title: 'Data Security',
                  bulletPoints: [
                    'Encryption of sensitive data',
                    'Secure storage of data',
                    'Regular security audits',
                  ],
                ),
                _buildSubSection(
                  title: 'Your Rights',
                  bulletPoints: [
                    'The right to access your data',
                    'The right to correct inaccurate data',
                    'The right to delete your data',
                  ],
                ),
                _buildParagraph(
                  'The privacy policy may be updated from time to time. We encourage you to review it regularly.',
                ),
              ],
            ),
            _buildCard(
              title: 'SafeTrack Terms of Use',
              content: [
                _buildParagraph(
                  'These Terms of Use govern your use of the SafeTrack app. By using SafeTrack, you agree to these terms.',
                ),
                _buildSubSection(
                  title: 'Acceptance of Terms',
                  content: 'By using the app, you agree to the terms of use.',
                ),
                _buildSubSection(
                  title: 'User Responsibilities',
                  bulletPoints: [
                    'Providing accurate information',
                    'Maintaining the confidentiality of your account information',
                    'Using the app responsibly and ethically',
                  ],
                ),
                _buildParagraph(
                  'The app is provided "as is" and without warranties. SafeTrack is not responsible for any data loss or technical issues that arise from using the app.',
                ),
                _buildParagraph(
                  'SafeTrack reserves the right to terminate accounts that violate these terms of use.',
                ),
              ],
            ),
            _buildCard(
              title: 'Non-Disclosure Agreement (NDA) Data Collection',
              content: [
                _buildParagraph(
                  'As part of the Non-Disclosure Agreement (NDA), SafeTrack ensures that the data collected will be used solely for the purposes outlined in the agreement. The data collected includes:',
                ),
                _buildSubSection(
                  title: 'Data Collected Under the NDA',
                  bulletPoints: [
                    'User identification information (name, email, contact details)',
                    'Sensitive business or project details provided for app customization',
                    'Data shared during beta testing or development phases',
                  ],
                ),
                _buildSubSection(
                  title: 'Purpose of Data Collection',
                  bulletPoints: [
                    'To ensure the confidentiality of shared information',
                    'To provide a tailored service based on user needs',
                    'To improve product functionality and security based on testing data',
                  ],
                ),
                _buildSubSection(
                  title: 'Data Protection Measures',
                  bulletPoints: [
                    'Restricted access to authorized personnel only',
                    'Encryption of data shared under the NDA',
                    'Secure storage and disposal of sensitive information',
                  ],
                ),
                _buildParagraph(
                  'By signing the NDA, you agree to these terms. If you have any concerns, please contact the SafeTrack support team.',
                ),
              ],
            ),
            _buildCard(
              title: 'Additional Information',
              content: [
                _buildParagraph(
                  'Relevant Laws:\n• Republic Act 10173 (Data Privacy Act of 2012)\n• Other applicable laws and regulations',
                ),
              ],
            ),
            _buildCard(
              title: 'Contact Information',
              content: [
                _buildParagraph(
                  'If you have questions about our legal and privacy policies, please contact the SafeTrack support team.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12.0),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    String? content,
    List<String>? bulletPoints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (content != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          if (bulletPoints != null)
            ...bulletPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
