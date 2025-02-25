import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountSettingsModal extends StatefulWidget {
  final String? profilePictureUrl;
  final String? username;
  final String? email;
  final String? firstname;
  final String? lastname;
  final String? address;
  final String? birthday;
  final String? role;
  final String? studentId;
  final Function onUpdate; // Callback to refresh the profile

  const AccountSettingsModal({
    super.key,
    this.profilePictureUrl,
    this.username,
    this.email,
    this.firstname,
    this.lastname,
    this.address,
    this.birthday,
    this.role,
    this.studentId,
    required this.onUpdate,
  });

  @override
  _AccountSettingsModalState createState() => _AccountSettingsModalState();
}

class _AccountSettingsModalState extends State<AccountSettingsModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username ?? '';
    _emailController.text = widget.email ?? '';
    _firstnameController.text = widget.firstname ?? '';
    _lastnameController.text = widget.lastname ?? '';
    _addressController.text = widget.address ?? '';
    _birthdayController.text = widget.birthday ?? '';
  }

  Future<void> _updateUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'username': _usernameController.text,
        'email': _emailController.text,
        'firstname': _firstnameController.text,
        'lastname': _lastnameController.text,
        'address': _addressController.text,
        'birthday': _birthdayController.text,
      });
      widget.onUpdate(); // Refresh the profile data after updating
      Navigator.of(context).pop(); // Close the modal
    } catch (e) {
      print("Failed to update user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context)
          .unfocus(), // Dismiss keyboard when tapping outside
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField('Username', _usernameController),
                _buildTextField('Email', _emailController),
                _buildTextField('First Name', _firstnameController),
                _buildTextField('Last Name', _lastnameController),
                _buildTextField('Address', _addressController),
                _buildTextField('Birthday', _birthdayController),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _updateUserData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintText: 'Enter $label',
          hintStyle: TextStyle(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label cannot be empty';
          }
          return null;
        },
      ),
    );
  }
}
