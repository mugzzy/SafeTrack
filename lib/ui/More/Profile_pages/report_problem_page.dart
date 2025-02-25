// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';

// class ReportProblemPage extends StatefulWidget {
//   const ReportProblemPage({super.key});

//   @override
//   _ReportProblemPageState createState() => _ReportProblemPageState();
// }

// class _ReportProblemPageState extends State<ReportProblemPage> {
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _contactInfoController = TextEditingController();
//   String? selectedCategory;
//   File? _image; // Only one image can be uploaded
//   bool _isSubmitting = false;

//   @override
//   void initState() {
//     super.initState();
//     dotenv.load(); // Load .env file
//   }

//   // Function to validate email format
//   bool _isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
//     return emailRegex.hasMatch(email);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report a Problem"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             const Text(
//               "If you are experiencing any issues, please fill out the form below.",
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 16.0),
//             _buildCategoryDropdown(),
//             const SizedBox(height: 16.0),
//             _buildDescriptionField(),
//             const SizedBox(height: 16.0),
//             _buildContactInfoField(),
//             const SizedBox(height: 16.0),
//             _buildImagePicker(),
//             const SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: _isSubmitting ? null : () => _submitReport(context),
//               child: _isSubmitting
//                   ? const CircularProgressIndicator()
//                   : const Text("Submit Report"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryDropdown() {
//     return DropdownButtonFormField<String>(
//       decoration: const InputDecoration(
//         labelText: "Select Problem Category",
//         border: OutlineInputBorder(),
//       ),
//       items: const [
//         DropdownMenuItem(value: "Technical", child: Text("Technical Issues")),
//         DropdownMenuItem(value: "Account", child: Text("Account Issues")),
//         DropdownMenuItem(
//             value: "Feedback", child: Text("Feedback/Suggestions")),
//         DropdownMenuItem(value: "Other", child: Text("Other")),
//       ],
//       onChanged: (value) {
//         setState(() {
//           selectedCategory = value;
//         });
//       },
//     );
//   }

//   Widget _buildDescriptionField() {
//     return TextField(
//       controller: _descriptionController,
//       maxLines: 5,
//       decoration: const InputDecoration(
//         labelText: "Describe the problem",
//         border: OutlineInputBorder(),
//       ),
//     );
//   }

//   Widget _buildContactInfoField() {
//     return TextField(
//       controller: _contactInfoController,
//       decoration: const InputDecoration(
//         labelText: "Your Contact Information (optional)",
//         border: OutlineInputBorder(),
//       ),
//     );
//   }

//   Widget _buildImagePicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Attach an image (optional):"),
//         const SizedBox(height: 8.0),
//         _image == null
//             ? ElevatedButton(
//                 onPressed: _pickImage,
//                 child: const Text("Pick Image"),
//               )
//             : Column(
//                 children: [
//                   Image.file(
//                     _image!,
//                     height: 150,
//                     fit: BoxFit.cover,
//                   ),
//                   TextButton(
//                     onPressed: _removeImage,
//                     child: const Text("Remove Image"),
//                   ),
//                 ],
//               ),
//         const SizedBox(height: 8.0),
//       ],
//     );
//   }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path); // Assign the picked image
//       });
//     }
//   }

//   void _removeImage() {
//     setState(() {
//       _image = null; // Remove the image
//     });
//   }

//   Future<void> _submitReport(BuildContext context) async {
//     setState(() {
//       _isSubmitting = true; // Show loading spinner
//     });

//     String description = _descriptionController.text.trim();
//     String contactInfo = _contactInfoController.text.trim();
//     String category = selectedCategory ?? "Uncategorized";

//     // Basic validation
//     if (description.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text("Error"),
//             content:
//                 const Text("Please fill in the required fields (Description)."),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("OK"),
//               ),
//             ],
//           );
//         },
//       );
//       setState(() {
//         _isSubmitting = false; // Hide loading spinner
//       });
//       return;
//     }

//     // Retrieve API Key from .env
//     final String apiKey =
//         dotenv.env['API_KEY'] ?? 'default_api_key'; // Fetch from .env

//     // Setup SMTP server using Gmail
//     String username = 'your_email@example.com'; // Replace with your email
//     String password = 'your_app_password'; // Replace with your App Password

//     final smtpServer = gmail(username, password); // Gmail SMTP server

//     // Prepare the email
//     final message = Message()
//       ..from = Address(username, 'Your Name')
//       ..recipients
//           .add('helpsafetrack@gmail.com') // The recipient's email address
//       ..subject = 'Problem Report: $category'
//       ..text = '''
//         Category: $category

//         Description: $description

//         Contact Info: $contactInfo
//       '''
//       ..attachments = _image != null ? [FileAttachment(_image!)] : [];

//     try {
//       print('Attempting to send email...'); // Debugging log
//       final sendReport = await send(message, smtpServer);
//       print('Email sent successfully!'); // Debugging log

//       // Show confirmation message
//       showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text("Report Submitted"),
//             content: const Text(
//                 "Thank you for your feedback! We will review your report shortly."),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context); // Close the confirmation dialog
//                   Navigator.pop(context); // Go back to the previous screen
//                 },
//                 child: const Text("OK"),
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       print('Error while sending email: $e'); // Debugging log

//       // Show error message
//       showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text("Error"),
//             content: Text("An error occurred while sending the report: $e"),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("OK"),
//               ),
//             ],
//           );
//         },
//       );
//     }

//     setState(() {
//       _isSubmitting = false; // Hide loading spinner
//     });
//   }
// }
