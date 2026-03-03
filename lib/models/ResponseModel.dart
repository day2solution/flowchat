// lib/models/api_response.dart

import 'dart:convert';

import 'package:flowchat/models/my_account.dart';

// Helper function to decode the full JSON string
ApiResponse apiResponseFromJson(String str) => ApiResponse.fromJson(json.decode(str));

class ApiResponse {
  final String status;
  final String? statusDesc;
  final MyAccount data;

  ApiResponse({
    required this.status,
    this.statusDesc,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
    status: json["status"],
    statusDesc: json["statusDesc"],
    // The key for the nested object is 'data', which we map to MyAccount
    data: MyAccount.fromJson(json["data"]),
  );
}