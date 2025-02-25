import 'package:capstone_1/models/sendnotif_model.dart';
import 'package:capstone_1/services/sendnotif_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentSendnotif extends StatefulWidget {
  const StudentSendnotif({super.key});

  @override
  _StudentSendnotifState createState() => _StudentSendnotifState();
}

class _StudentSendnotifState extends State<StudentSendnotif> {
  late MethodsSendNotif methodsSendNotif;
  late final SendNotifModel model;
  bool isLoading = true;
  bool hasError = false;
  bool isEditing = false;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> selectedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMessage();
    model = SendNotifModel(
      context: context,
      setState: (VoidCallback fn) => setState(fn),
      selectedContacts: selectedContacts,
      isLoading: isLoading,
      controller: _controller,
      hasError: hasError,
    );
    methodsSendNotif = MethodsSendNotif(model: model);
    methodsSendNotif.getLoggedInUserEmail();
  }

  Future<void> _loadSavedMessage() async {
    final prefs = await SharedPreferences.getInstance();
    _controller.text = prefs.getString('helpMessage') ?? '';
  }

  Future<void> _saveHelpMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('helpMessage', _controller.text);
  }

  Future<void> _sendEmergencyNotification() async {
    try {
      methodsSendNotif.sendEmergencyNotification();
      _showDialog(true);
    } catch (e) {
      setState(() => hasError = true);
      _showDialog(false, errorMsg: e.toString());
    }
  }

  void _showDialog(bool isSuccess, {String? errorMsg}) {
    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        });
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.blueAccent : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? 'Notification Sent' : 'Error',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isSuccess
                    ? 'The emergency notification has been successfully sent.'
                    : 'Failed to send notification: $errorMsg',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Notification',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SEND TO:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help Message:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isEditing
                          ? TextField(
                              key: const ValueKey(1),
                              controller: _controller,
                              maxLines: null,
                              autofocus: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Enter emergency message...',
                              ),
                            )
                          : Text(
                              _controller.text.isNotEmpty
                                  ? _controller.text
                                  : 'No message set',
                              key: const ValueKey(2),
                              style: const TextStyle(fontSize: 14),
                            ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    setState(() => isEditing = !isEditing);
                    if (!isEditing && _controller.text.isNotEmpty) {
                      await _saveHelpMessage();
                    }
                  },
                  child: Text(
                    isEditing ? 'SAVE' : 'EDIT',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _sendEmergencyNotification,
                icon: const Icon(Icons.notification_important),
                label: const Text('Send Emergency Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
