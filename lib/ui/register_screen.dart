import 'package:capstone_1/ui/More/Profile_pages/legal_and_policies_page.dart';
import 'package:capstone_1/ui/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final String email;
  final String displayName;
  final Function(String) onRegisterSuccess;

  const RegisterScreen({
    Key? key,
    required this.email,
    required this.displayName,
    required this.onRegisterSuccess,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;

  // Track the current form step
  int _currentStep = 0;

  // Form controllers for each step
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController teacherKeyController = TextEditingController();
  final TextEditingController studentIDController = TextEditingController();

  // Other variables
  String role = '';
  bool _isLoading = false;
  bool _obscureText = true;
  bool _viewedTerms = false;
  bool _isRegistrationCancelled = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controllers with data passed from Google Sign-In
    emailController.text = widget.email;
    firstnameController.text = widget.displayName.split(' ').first;
    lastnameController.text = widget.displayName.split(' ').last;
    usernameController.text = widget.displayName.replaceAll(' ', '_');
  }

  @override
  Future<void> dispose() async {
    // Handle the cancellation here if registration was not completed
    if (_currentStep < 3 && !_isLoading) {
      _isRegistrationCancelled = true;

      if (_isRegistrationCancelled) {
        String tempUid = FirebaseAuth.instance.currentUser?.uid ?? '';

        if (tempUid.isNotEmpty) {
          // Delete the temporary user from authentication
          await _authService.deleteUser(tempUid);

          // Delete the user document from Firestore's users collection
          try {
            final firestore = FirebaseFirestore.instance;
            await firestore.collection('users').doc(tempUid).delete();
            print('User document deleted from Firestore.');
          } catch (e) {
            print('Error deleting user from Firestore: $e');
          }

          print('Temporary user deleted upon registration cancellation.');
        }
      }
    }

    // Dispose controllers
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    addressController.dispose();
    birthdayController.dispose();
    teacherKeyController.dispose();
    studentIDController.dispose();

    super.dispose();
  }

  // Helper validation methods
  String? emailValidator(String? val) {
    if (val == null || val.isEmpty || !val.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? passwordValidator(String? val) {
    if (val == null || val.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? nonEmptyValidator(String? val, String fieldName) {
    if (val == null || val.isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  // Navigation methods
  void _nextStep() {
    if (_currentStep == 1) {
      if (role == 'Teacher' && teacherKeyController.text != '1234') {
        _showPopup('Invalid Teacher Key', isSuccess: false);
        return;
      }
      if (role == 'Student' && studentIDController.text.isEmpty) {
        _showPopup('Student ID cannot be empty', isSuccess: false);
        return;
      }
    }
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      _showPopup('Please fix the errors before proceeding', isSuccess: false);
      return;
    }
    setState(() {
      if (role == 'Parent' && _currentStep == 0) {
        _currentStep = 2; // Skip role-specific fields for "Parent"
      } else {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        if (role == 'Parent' && _currentStep == 2) {
          _currentStep = 0;
        } else {
          _currentStep--;
        }
      }
    });
  }

  // Display popup for validation errors or success messages
  void _showPopup(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = emailController.text;
      final username = usernameController.text;
      final studentID = studentIDController.text;

      try {
        if (await _authService.isEmailTaken(email)) {
          _showPopup('Email is already in use.', isSuccess: false);
          return;
        }

        if (await _authService.isUsernameTaken(username)) {
          _showPopup('Username is already in use.', isSuccess: false);
          return;
        }

        if (role == 'Student' &&
            studentID.isNotEmpty &&
            await _authService.isStudentIDTaken(studentID)) {
          _showPopup('Student ID is already in use.', isSuccess: false);
          return;
        }

        final result = await _authService.registerOrUpdate(
          email,
          passwordController.text,
          role,
          username: username,
          firstname: firstnameController.text,
          lastname: lastnameController.text,
          address: addressController.text,
          birthday: birthdayController.text,
          teacherKey: teacherKeyController.text,
          studentID: studentID,
        );

        if (result['success']) {
          _showPopup('Registration successful! Please login.', isSuccess: true);
          // Navigate to the login screen after showing the success message
          await Future.delayed(
              Duration(seconds: 1)); // Optional delay for message display
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          _showPopup(result['error'] ?? 'Registration failed',
              isSuccess: false);
        }
      } catch (e) {
        _showPopup('An error occurred: $e', isSuccess: false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_currentStep == 0) _buildRoleSelection(),
              if (_currentStep == 1) _buildRoleSpecificFields(),
              if (_currentStep == 2) _buildPersonalDetailsForm(),
              if (_currentStep == 3) _buildAccountDetailsForm(),
              const SizedBox(height: 20),
              if (_currentStep == 3)
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Register'),
                      ),
              const SizedBox(height: 20),
              if (_currentStep == 0)
                TextButton(
                  child: const Text('Already have an account? Login here'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Select Role",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            _buildRoleBox('Student', Icons.person, _termsAccepted),
            const SizedBox(height: 20),
            _buildRoleBox('Teacher', Icons.school, _termsAccepted),
            const SizedBox(height: 20),
            _buildRoleBox('Parent', Icons.people, _termsAccepted),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: _viewedTerms
                  ? (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    }
                  : null, // Disable if terms haven't been viewed
            ),
            Expanded(
              child: Text(
                "I have read and accept the terms and conditions.",
                style: TextStyle(
                  fontSize: 16,
                  color: _viewedTerms
                      ? Colors.black
                      : Colors.grey, // Dynamic color
                ),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LegalAndPoliciesPage(
                  isRegisterScreen: true,
                ),
              ),
            );
            setState(() {
              _viewedTerms = true; // Mark as viewed when user returns
            });
          },
          child: const Text(
            "View Terms and Conditions",
            style: TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBox(String roleTitle, IconData icon, bool isEnabled) {
    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          setState(() {
            role = roleTitle;
          });
          _nextStep();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Please read and accept the terms and conditions first.",
                style: TextStyle(fontSize: 16),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      child: Container(
        width: 270, // Set a fixed narrow width
        margin: const EdgeInsets.symmetric(
            vertical: 10), // Add spacing between boxes
        padding: const EdgeInsets.symmetric(
            vertical: 30), // Compact vertical padding
        decoration: BoxDecoration(
          color:
              isEnabled ? Colors.blueAccent : Colors.grey, // Grey if disabled
          borderRadius: BorderRadius.circular(10), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          // Use Column for centered layout
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon,
                color: isEnabled ? Colors.white : Colors.black38,
                size: 30), // Grey icon if disabled
            const SizedBox(height: 8), // Spacing between icon and text
            Text(
              roleTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Compact font size
                fontWeight: FontWeight.bold,
                color: isEnabled
                    ? Colors.white
                    : Colors.black38, // Grey text if disabled
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificFields() {
    switch (role) {
      case 'Student':
        return Column(
          children: [
            _buildTextFormField(studentIDController, 'Student ID',
                validator: (val) => nonEmptyValidator(val, 'Student ID')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavigationButton('Back', _previousStep),
                _buildNavigationButton('Next', _nextStep),
              ],
            ),
          ],
        );
      case 'Teacher':
        return Column(
          children: [
            _buildTextFormField(teacherKeyController, 'Teacher Key',
                validator: (val) => nonEmptyValidator(val, 'Teacher Key')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavigationButton('Back', _previousStep),
                _buildNavigationButton('Next', _nextStep),
              ],
            ),
          ],
        );
      case 'Parent':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavigationButton('Back', _previousStep),
                _buildNavigationButton('Next', _nextStep),
              ],
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildPersonalDetailsForm() {
    return Column(
      children: [
        _buildTextFormField(firstnameController, 'First Name',
            validator: (val) => nonEmptyValidator(val, 'First Name')),
        const SizedBox(height: 20),
        _buildTextFormField(lastnameController, 'Last Name',
            validator: (val) => nonEmptyValidator(val, 'Last Name')),
        const SizedBox(height: 20),
        _buildTextFormField(addressController, 'Address',
            validator: (val) => nonEmptyValidator(val, 'Address')),
        const SizedBox(height: 20),
        _buildDatePickerField(birthdayController, 'Birthday (MM/DD/YYYY)'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavigationButton('Back', _previousStep),
            _buildNavigationButton('Next', _nextStep),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true, // Make the field read-only
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900), // Earliest possible date
          lastDate: DateTime.now(), // Latest possible date
        );
        if (pickedDate != null) {
          // Format the selected date and set it to the controller
          controller.text =
              "${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}";
        }
      },
      validator: (val) => nonEmptyValidator(val, 'Birthday'),
    );
  }

  Widget _buildAccountDetailsForm() {
    return Column(
      children: [
        _buildTextFormField(emailController, 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator),
        const SizedBox(height: 20),
        _buildTextFormField(usernameController, 'Username',
            validator: (val) => nonEmptyValidator(val, 'Username')),
        const SizedBox(height: 20),
        _buildPasswordFormField(passwordController, 'Password'),
        const SizedBox(height: 20),
        _buildPasswordFormField(confirmPasswordController, 'Confirm Password',
            validator: (val) {
          if (val == null || val != passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        }),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavigationButton('Back', _previousStep),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordFormField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      obscureText: _obscureText,
      validator: validator,
    );
  }

  Widget _buildNavigationButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 25),
        backgroundColor: Colors.blueAccent,
        textStyle:
            const TextStyle(fontSize: 18), // For text style within the button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Set corner radius here
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white), // Set text color to white
      ),
    );
  }
}
