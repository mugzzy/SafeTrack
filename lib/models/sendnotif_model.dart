import 'package:flutter/material.dart';

class SendNotifModel {
  final BuildContext context;
  final Function setState;
  String? loggedInUserStudentId;
  String? loggedInUserEmail;
  late final List<Map<String, dynamic>> selectedContacts;
  bool isLoading;
  final TextEditingController controller;
  bool hasError;

  SendNotifModel({
    required this.context,
    required this.setState,
    this.loggedInUserStudentId,
    this.loggedInUserEmail,
    required this.selectedContacts,
    required this.isLoading,
    required this.controller,
    required this.hasError,
  });
}
