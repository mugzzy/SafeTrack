import 'package:flutter/material.dart';

class UserInfoModal extends StatelessWidget {
  final String? profilePictureUrl;
  final String? fullName;
  final String? email;
  final String? username;
  final String? studentID;
  final String? address;
  final String? birthday;
  final VoidCallback onRefresh;

  const UserInfoModal({
    super.key,
    this.profilePictureUrl,
    this.fullName,
    this.email,
    this.username,
    this.studentID,
    this.address,
    this.birthday,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                  ? NetworkImage(profilePictureUrl!)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(fullName ?? 'N/A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            _buildUserInfoText('Username: ${username ?? 'N/A'}'),
            _buildUserInfoText('Email: ${email ?? 'N/A'}'),
            _buildUserInfoText('Student ID: ${studentID ?? 'N/A'}'),
            _buildUserInfoText('Address: ${address ?? 'N/A'}'),
            _buildUserInfoText('Birthdate: ${birthday ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(text, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
    );
  }
}
