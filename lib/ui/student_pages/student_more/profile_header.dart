import 'package:capstone_1/ui/More/Profile_pages/profile_view_more.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? profilePictureUrl;
  final String? fullName;
  final String? email;
  final VoidCallback onEdit;

  const ProfileHeader({
    super.key,
    this.profilePictureUrl,
    this.fullName,
    this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                    ? NetworkImage(profilePictureUrl!)
                    : const AssetImage('assets/default_profile.png')
                        as ImageProvider,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to ParentProfileView when the full name is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileViewMore(onUpdate: () {}),
                      ),
                    );
                  },
                  child: Text(
                    fullName ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    // Navigate to ParentProfileView when email is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileViewMore(onUpdate: () {}),
                      ),
                    );
                  },
                  child: Text(
                    email ?? 'N/A',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.expand_circle_down_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
