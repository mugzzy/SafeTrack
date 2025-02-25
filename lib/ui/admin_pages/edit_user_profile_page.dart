import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import this for date formatting

class EditUserProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUserProfilePage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  _EditUserProfilePageState createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _addressController;
  late TextEditingController _birthdayController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _studentIdController;
  String _selectedRole = 'Student';

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.userData['username'] ?? '');
    _firstnameController =
        TextEditingController(text: widget.userData['firstname'] ?? '');
    _lastnameController =
        TextEditingController(text: widget.userData['lastname'] ?? '');
    _addressController =
        TextEditingController(text: widget.userData['address'] ?? '');
    _birthdayController =
        TextEditingController(text: widget.userData['birthday'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _passwordController = TextEditingController();
    _studentIdController =
        TextEditingController(text: widget.userData['studentID'] ?? '');
    _selectedRole = widget.userData['role'] ?? 'Student';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'username': _usernameController.text,
        'firstname': _firstnameController.text,
        'lastname': _lastnameController.text,
        'address': _addressController.text,
        'birthday': _birthdayController.text,
        'email': _emailController.text,
        if (_passwordController.text.isNotEmpty)
          'password': _passwordController.text, // Only update if non-empty
        if (_selectedRole == 'Student')
          'studentID':
              _studentIdController.text, // Only include if role is Student
        'role': _selectedRole,
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a username'
                    : null,
              ),
              TextFormField(
                controller: _firstnameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a first name'
                    : null,
              ),
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a last name'
                    : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an address'
                    : null,
              ),
              TextFormField(
                controller: _birthdayController,
                decoration: const InputDecoration(labelText: 'Birthday'),
                readOnly: true, // Prevent manual input
                onTap: () => _selectDate(context), // Show date picker
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a birthday'
                    : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an email'
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              // Conditionally display Student ID field based on selected role
              if (_selectedRole == 'Student')
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                  validator: (value) {
                    if (_selectedRole == 'Student' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter a student ID';
                    }
                    return null; // No error for other roles
                  },
                ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'Student', child: Text('Student')),
                  DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                ],
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close without saving
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Changes'),
                content: const Text(
                    'Are you sure you want to save these changes? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(), // Cancel confirmation
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close the confirmation dialog
                      _updateUser(); // Save changes
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
