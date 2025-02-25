import 'package:capstone_1/models/request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/request_service.dart';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  _ParentProfilePageState createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  final TextEditingController _accountIdController = TextEditingController();
  final RequestService _requestService = RequestService();
  String? _parentUsername;
  String? _parentId;
  String? _parentEmail;
  // ignore: unused_field
  List<RequestModel> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchParentId();
    _fetchRequests();
  }

  void _fetchParentId() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _parentId = user.uid; // Store user ID
        _parentEmail = user.email; // Get parent email
      });

      // Fetch parent username using _parentId
      try {
        final username = await _requestService.getUsernameByParentId(user.uid);
        setState(() {
          _parentUsername =
              username ?? 'Unknown'; // Default to 'Unknown' if null
        });
      } catch (e) {
        debugPrint('Error fetching parent username: $e');
      }
    }
  }

  void _fetchRequests() async {
    if (_parentId != null && _parentId!.isNotEmpty) {
      try {
        // Resolve the future and then filter the results
        final allRequests =
            await _requestService.getRequestsByParent(_parentId!).first;
        _requests = allRequests
            .where((request) => ['Pending', 'Accepted', 'Declined', 'Cancelled']
                .contains(request.status))
            .toList(); // Filter requests by status
        setState(() {}); // Update UI
      } catch (e) {
        debugPrint('Error fetching requests: $e');
      }
    } else {
      debugPrint('Error: _parentId is null or empty');
    }
  }

  void _cancelRequest(String requestId) async {
    bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmCancel == true) {
      bool success = false;
      try {
        await _requestService.cancelRequest(requestId);
        success = true;
      } catch (e) {
        debugPrint('Error cancelling request: $e');
        success = false;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.blueAccent : Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  success
                      ? 'Request cancelled successfully'
                      : 'Failed to cancel request',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (success) {
        _fetchRequests(); // Refresh the list
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Accepted':
        color = Colors.blue;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Declined':
        color = Colors.red;
        break;
      case 'Cancelled': // Handle Cancelled status
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink(); // Don't show for other statuses
    }
    return Chip(
      label: Text(status.toUpperCase(),
          style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size =
            MediaQuery.of(context).size; // Screen size for responsiveness

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            width: size.width * 0.8, // Dynamic width
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Request',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 20),

                  // Input Field
                  TextField(
                    controller: _accountIdController,
                    decoration: InputDecoration(
                      labelText: 'Account ID',
                      hintText: 'Enter your child\'s Account ID',
                      labelStyle: const TextStyle(color: Colors.blueGrey),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      helperText: 'Ensure the Account ID is correct.',
                      helperStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Send Button
                  ElevatedButton(
                    onPressed: () async {
                      final accountId = _accountIdController.text.trim();
                      if (accountId.isEmpty ||
                          _parentId!.isEmpty ||
                          _parentEmail == null) {
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('Validation Error'),
                            content: Text(
                              'Please provide a valid Account ID and ensure you are logged in.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Account validation logic
                      bool isAccountAuthenticated =
                          await _requestService.checkIfAccountExists(accountId);

                      if (!isAccountAuthenticated) {
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('Invalid Account'),
                            content: Text(
                                'This Account ID does not exist. Please check and try again.'),
                          ),
                        );
                        return;
                      }

                      try {
                        await _requestService.sendRequest(
                          _parentEmail!,
                          _parentId!,
                          accountId,
                          _parentUsername,
                        );
                        _fetchRequests();
                        Navigator.of(context).pop();

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.blueAccent,
                                    size: 60,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Request sent successfully!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Failed to send request: ${e.toString()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      backgroundColor: Colors.blueAccent,
                      shadowColor: Colors.blueAccent.withOpacity(0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 20, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Send Request',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_parentId == null || _parentId!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _parentUsername ?? "Parent",
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showRequestDialog,
                  child: const Icon(Icons.add),
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: _requestService.getRequestsByParent(_parentId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No requests found.'));
                }

                final requests = snapshot.data!
                    .where((request) => ['Pending', 'Accepted', 'Declined']
                        .contains(request.status)) // Filter the status
                    .toList();

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text('Account ID: ${request.childAccountId}'),
                        trailing: _buildStatusChip(request.status),
                        onTap: request.status == 'Pending'
                            ? () => _cancelRequest(request.id)
                            : null, // Only allow cancel if status is Pending
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    super.dispose();
  }
}
