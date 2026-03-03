import 'dart:convert';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/models/ResponseModel.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = Environment.hostApiUrl;

  Future<dynamic> getUser(String contactNo) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/auth/users/$contactNo'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      // Handle exceptions like no internet connection, etc.
      debugPrint('Error in getUser: $e');
      return null;
    }
  }
  Future<MyAccount?> fetchUserData(String contactNo) async {
    String url='$_baseUrl/api/auth/login/$contactNo';
    debugPrint("url=$url");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Use the helper function to parse the entire response
      final apiResponse = apiResponseFromJson(response.body);

      if (apiResponse.status == "SUCCESS") {
        // Return the nested 'data' object which is of type MyAccount
        debugPrint("success found");
        return apiResponse.data;
      }
    }
    debugPrint("failure found");
    // Return null if the request failed or status is not SUCCESS
    return null;
  }

  Future<ApiResponse?> updateUserFullName(Map<String, String> userData) async {
    try {
      final response = await http.put(
        // Assuming your endpoint for updating the user is '/users/update/name'
        Uri.parse('$_baseUrl/api/users/update-name'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        return apiResponseFromJson(response.body);
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception('Failed to update user name. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in updateUserFullName: $e');
      return null;
    }
  }

  Future<ApiResponse?> updateProfile(Map<String, String> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/update-profile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return apiResponseFromJson(response.body);
      } else {
        throw Exception('Failed to update user name. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in updateUserFullName: $e');
      return null;
    }
  }
  Future<dynamic> registerUser(Map<String, String> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) { // 201 Created is common for successful POSTs
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register user. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in registerUser: $e');
      return null;
    }
  }
}
