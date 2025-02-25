import 'package:flutter/material.dart';

import '../../models/request_model.dart';

class RequestListItem extends StatelessWidget {
  final RequestModel request;

  const RequestListItem({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Account ID: ${request.childAccountId}'),
      subtitle: Text(
          'Status: ${request.status}\nTime: ${request.timestamp.toLocal()}'),
      tileColor: Colors.grey[800],
      textColor: Colors.white,
      trailing: const Icon(Icons.more_vert, color: Colors.white),
    );
  }
}
