import 'package:flutter/material.dart';

import '../../../services/cache_service.dart';

class EmergencyContactListPage extends StatefulWidget {
  const EmergencyContactListPage({super.key});

  @override
  _EmergencyContactListPageState createState() =>
      _EmergencyContactListPageState();
}

class _EmergencyContactListPageState extends State<EmergencyContactListPage> {
  final CacheService _cacheService = CacheService();
  List<Map<String, dynamic>> _selectedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedContacts();
  }

  Future<void> _loadSelectedContacts() async {
    try {
      List<Map<String, dynamic>> cachedParents =
          await _cacheService.loadSelectedParents();
      setState(() {
        _selectedContacts = cachedParents;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load selected contacts: $e')),
      );
    }
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    setState(() {
      _selectedContacts.remove(contact);
    });
    await _cacheService.saveSelectedParents(_selectedContacts);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact deleted successfully')),
    );
  }

  Future<bool?> _confirmDeleteDialog(String parentName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete "$parentName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _selectedContacts.isNotEmpty
          ? ListView.builder(
              itemCount: _selectedContacts.length,
              itemBuilder: (context, index) {
                final contact = _selectedContacts[index];

                final username = contact['username'] ?? 'N/A';

                return ContactCard(
                  contact: contact,
                  onDelete: () => _deleteContact(contact),
                  confirmDeleteDialog: () => _confirmDeleteDialog(username),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onDelete;
  final Future<bool?> Function() confirmDeleteDialog;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onDelete,
    required this.confirmDeleteDialog,
  });

  @override
  Widget build(BuildContext context) {
    final email = contact['email'] ?? 'N/A';
    final imageUrl = contact['profileImage'] ?? '';
    final username = contact['username'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          username,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(email),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              final confirmed = await confirmDeleteDialog();
              if (confirmed ?? false) {
                onDelete();
              }
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Remove Contact'),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }
}
