import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  _AuditLogsPageState createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final AuditLogService _auditLogService = AuditLogService();
  String selectedDate = DateTime.now().toLocal().toString().split(' ')[0];
  int _currentPage = 0;
  final int _logsPerPage = 10; // Number of logs to display per page

  // Format timestamp to desired format: HH:MM XM - YYYY-MM-DD
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'} - ${dateTime.toIso8601String().split('T')[0]}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Picker
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Select Date: '),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate =
                          pickedDate.toLocal().toString().split(' ')[0];
                      _currentPage =
                          0; // Reset to the first page when a new date is selected
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _auditLogService.getAuditLogsByDate(selectedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No logs found for this date.'));
              }

              List<Map<String, dynamic>> logs = snapshot.data!;
              int totalPages = (logs.length / _logsPerPage).ceil();

              // Get logs for the current page
              List<Map<String, dynamic>> logsForPage = logs
                  .skip(_currentPage * _logsPerPage)
                  .take(_logsPerPage)
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Activity')),
                          DataColumn(label: Text('Timestamp')),
                        ],
                        rows: logsForPage.map((log) {
                          return DataRow(cells: [
                            DataCell(Text(log['username'] ?? 'N/A')),
                            DataCell(Text(log['email'] ?? 'N/A')),
                            DataCell(Text(log['role'] ?? 'N/A')),
                            DataCell(Text(log['activity'] ?? 'N/A')),
                            DataCell(Text(formatTimestamp(
                                log['timestamp'] ?? Timestamp.now()))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  // Pagination controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),
                      Text('Page ${_currentPage + 1} of $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _currentPage < totalPages - 1
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
              );
            },
          ),
        ),
      ],
    );
  }
}
