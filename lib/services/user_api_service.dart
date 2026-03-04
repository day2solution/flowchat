import 'dart:convert';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/models/update_name_request.dart';
import 'package:http/http.dart' as http;

class UserApiService {
  final String baseUrl = "${Environment.hostApiUrl}/api/users";
  // use 10.0.2.2 for Android emulator, localhost for web

  Future<Map<String, dynamic>> updateUserName(UpdateNameRequest request) async {
    final response = await http.put(
      Uri.parse("$baseUrl/update-name"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update name: ${response.body}");
    }
  }
}
