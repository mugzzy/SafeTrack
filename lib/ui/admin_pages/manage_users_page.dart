import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'edit_user_profile_page.dart'; // Import the edit page

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String _selectedRole = 'All';
  bool _isLoading = true;
  int _currentPage = 1;
  final int _usersPerPage = 10;

  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      _users = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'profilePic': data['profilePicture'],
          'username': data['username'] ?? '',
          'firstname': data['firstname'] ?? '',
          'lastname': data['lastname'] ?? '',
          'email': data['email'] ?? '',
          'studentID': data['studentID'] ?? '',
          'birthday': data['birthday'] ?? '',
          'role': data['role'] ?? 'N/A',
          'address': data['address'] ?? '',
        };
      }).toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> users =
        _users.where((user) => user['role'] != 'Admin').toList();

    if (_selectedRole != 'All') {
      users = users.where((user) => user['role'] == _selectedRole).toList();
    }

    if (_searchQuery.isNotEmpty) {
      users = users.where((user) {
        final fullName = '${user['firstname']} ${user['lastname']}';
        return fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user['studentID']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            user['birthday'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return users;
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _filteredUsers.length;
    final totalPages = (totalUsers / _usersPerPage).ceil();
    final startIndex = (_currentPage - 1) * _usersPerPage;
    final endIndex = startIndex + _usersPerPage;
    final safeEndIndex = endIndex > totalUsers ? totalUsers : endIndex;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Manage Users'),
        actions: [
          DropdownButton<String>(
            value: _selectedRole,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onChanged: _filterByRole,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Student', child: Text('Student')),
              DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
              DropdownMenuItem(value: 'Parent', child: Text('Parent')),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _isLoading
              ? const Center(child: SpinKitFadingCircle(color: Colors.blue))
              : Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 250, // Adjust width as needed
                            child: TextField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[200], // Background color
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(30), // Rounded
                                  borderSide: BorderSide.none, // No border
                                ),
                                prefixIcon: const Icon(Icons.search), // Icon
                                hintText: 'Search user here', // Placeholder
                                hintStyle:
                                    const TextStyle(color: Colors.grey), // Hint style
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _currentPage = 1; // Reset on search
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Profile Pic')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Student ID')),
                              DataColumn(label: Text('Birthdate')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: List<DataRow>.generate(
                              safeEndIndex - startIndex,
                              (index) {
                                final user = _filteredUsers[startIndex + index];
                                return DataRow(cells: [
                                  DataCell(
                                    user['profilePic'] != null
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                user['profilePic']),
                                          )
                                        : const CircleAvatar(),
                                  ),
                                  DataCell(Text(
                                      '${user['firstname']} ${user['lastname']}')),
                                  DataCell(Text(user['email'])),
                                  DataCell(Text(user['studentID'])),
                                  DataCell(Text(user['birthday'])),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditUserDialog(user['id'], user);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(
                                              user['id']);
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              },
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text('Page $_currentPage of $totalPages'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _currentPage < totalPages
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  void _filterByRole(String? role) {
    if (role != null) {
      setState(() {
        _selectedRole = role;
        _currentPage = 1;
      });
    }
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditUserProfilePage(
        userId: userId,
        userData: userData,
      ),
    );

    if (result == true) {
      _fetchUsers(); // Refresh the list after editing
    }
  }

  void _showDeleteConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteUser(userId);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
