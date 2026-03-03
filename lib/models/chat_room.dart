import 'user.dart';
import 'chat_message.dart';

class ChatRoom {
  final String id;
  final String name;
  final List<User> members;
  List<ChatMessage> messages;
  int unread;

  ChatRoom({
    required this.id,
    required this.name,
    required this.members,
    this.messages = const [],
    this.unread = 0,
  });
}
