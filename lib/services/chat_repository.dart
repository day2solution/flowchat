import 'package:flowchat/config/Logger.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/services/api-service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';

import '../models/chat_message.dart';
import 'db_service.dart';
import 'web_socket_service.dart';

class ChatRepository {
  final WebSocketService _ws = WebSocketService();
  final DbService _db = DbService();
  // final ChatDb _chatDb = ChatDb();
  final ApiService _apiService = ApiService();
  void connectUser(String userId) => _ws.connect(userId);

  void sendText(String chatId, String senderId, String content,String receiverId) => _ws.sendTextMessage(chatId, senderId, content,receiverId);

  Future<List<ChatMessage>> loadMessages(String chatId) => _db.getMessages(chatId);
  Future<void> listAllTables() => _db.listAllTables();
  Future<List<ChatMessage>> loadAllMessages() => _db.getAllMessages();
  Future<List<User>> getRecentChats() => _db.getChats();
  Future<void> clearRecentChats() => _db.clearRecentChats();
  Future<void> saveMyAccount(MyAccount myaccount) => _db.saveMyAccount(myaccount);
  Future<List<MyAccount>> getMyAccount(String contactNo) => _db.getMyAccount(contactNo);
  Future<List<MyAccount>> getAllMyAccount() => _db.getAllMyAccount();
  Future<void> clearMyAccount() => _db.clearMyAccount();

  void onIncoming(void Function(ChatMessage) cb) => _ws.onMessage(cb);
  void onMsgStatus(void Function(String,String) cb) => _ws.onMsgStatusAction(cb);
  void onUserPresence(void Function(String,bool) cb) => _ws.onUserPresence(cb);
  void onTyping(void Function(String) cb) => _ws.onTyping(cb);

  // In lib/services/chat_repository.dart

  Future<MyAccount?> fetchUserFromApi(String contactNo) async {
    try {
      // The API service now returns the MyAccount model from api_response.dart
      final apiAccountData = await _apiService.fetchUserData(contactNo);
      Logger.log("api-service","apiAccountData=${apiAccountData}");
      if (apiAccountData != null) {
        // Create an instance of the DB-compatible MyAccount model
        final dbAccount = MyAccount(
          contactNo: apiAccountData.contactNo,
          name: apiAccountData.name??'',
          about: apiAccountData.about ?? '', // Handle potential null 'about'
        );

        // Save the DB-compatible model to the local database
        await saveMyAccount(dbAccount);

        // Return the DB-compatible model
        return dbAccount;
      }
    } catch (e) {
      Logger.log("api-service","Failed to fetch user from API: $e");
    }
    return null;
  }
  Future<MyAccount?> updateUserFullNameApi(MyAccount accountToUpdate,BuildContext context) async {
    try {
      final apiResponse = await _apiService.updateUserFullName({
        'contactNo': accountToUpdate.contactNo,
        'name': accountToUpdate.name??'',
      });
      if (apiResponse != null && apiResponse.status == "SUCCESS") {
        final updatedApiAccount = apiResponse.data;
        final dbAccount = MyAccount(
          contactNo: updatedApiAccount.contactNo,
          name: updatedApiAccount.name,
          about: updatedApiAccount.about ?? '', // Handle null 'about'
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Details updated successfully"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
          ),
        );
        await saveMyAccount(dbAccount);
        return dbAccount;
      }
    } catch (e) {
      Logger.log("api-service","Failed to update user and save to DB: $e");
    }
    return null;
  }

  Future<MyAccount?> updateMyProfile(MyAccount accountToUpdate,BuildContext context) async {
    try {
      final apiResponse = await _apiService.updateProfile(
          {
            'contactNo': accountToUpdate.contactNo,
            'name': accountToUpdate.name??'',
            'about': accountToUpdate.about??'',
          }
      );
      if (apiResponse != null && apiResponse.status == "SUCCESS") {
        final updatedApiAccount = apiResponse.data;
        final dbAccount = MyAccount(
          contactNo: updatedApiAccount.contactNo,
          name: updatedApiAccount.name,
          about: updatedApiAccount.about ?? '', // Handle null 'about'
        );
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text("Profile updated successfully"),
        //     behavior: SnackBarBehavior.floating,
        //     backgroundColor: Colors.green.shade700,
        //   ),
        // );
        await saveMyAccount(dbAccount);
        return dbAccount;
      }
    } catch (e) {
      Logger.log("api-service","Failed to update user and save to DB: $e");
    }
    return null;
  }
}
