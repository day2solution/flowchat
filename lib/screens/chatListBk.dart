import 'dart:convert';
import 'package:flowchat/constant.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_screen.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import 'package:uuid/uuid.dart';

class ChatListScreen extends StatefulWidget {
  final String loggedInusername;
  final String loggedInContact;
  const ChatListScreen({
    required this.loggedInusername,
    required this.loggedInContact,
    super.key,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _rooms = <ChatRoom>[];
  final TextEditingController _searchController = TextEditingController();
  final ChatRepository _repo = ChatRepository();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Demo seed
    _repo.onUserPresence(_handlePresence);
  }
  void _handlePresence(String userId, bool status)  {
    if (!mounted) return;
    final index = _searchResults.indexWhere((m) => m.contactNo == userId);
    if (index != -1) {
      setState(() {
        _searchResults[index].online = status;
      });
    }
  }
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConstant.HOST}/api/users/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.map((e) => User.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error searching users: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _openChat(User peer) {
    // final existingRoom = _rooms.firstWhere(
    //       (r) => r.members.any((m) => m.id == peer.id),
    //   orElse: () => ChatRoom(
    //     id: const Uuid().v4(),
    //     name: peer.name,
    //     members: [peer],
    //     messages: [],
    //   ),
    // );
    //
    // if (!_rooms.contains(existingRoom)) {
    //   setState(() => _rooms.add(existingRoom));
    // }
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => ChatScreen(
    //       loggedUserName: widget.loggedInusername,
    //       loggedUserContact: widget.loggedInContact,
    //       peer: peer,
    //     ),
    //   ),
    // );
  }

  Widget _buildChatTile(ChatRoom room) {
    final lastMessage =
    room.messages.isNotEmpty ? room.messages.last.content : "No messages yet";
    final time =
    room.messages.isNotEmpty ? "12:30 PM" : ""; // mock time, replace with actual timestamp

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal,
        child: Text(room.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white)),
      ),
      title: Text(
        room.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => ChatScreen(
        //       loggedUserName: widget.loggedInusername,
        //       loggedUserContact: widget.loggedInContact,
        //       peer: room.members.first,
        //     ),
        //   ),
        // );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatsToShow = _searchResults.isNotEmpty ? _searchResults : [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: _showSearch
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _searchUsers,
        )
            : const Text("WhatsApp Clone"),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                _searchResults.clear();
                _searchController.clear();
              });
            },
          ),
          PopupMenuButton<String>(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: "new_group", child: Text("New group")),
              const PopupMenuItem(value: "settings", child: Text("Settings")),
            ],
          )
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : chatsToShow.isNotEmpty
          ? ListView.separated(
        itemCount: chatsToShow.length,
        separatorBuilder: (_, __) => const Divider(height: 0.5),
        itemBuilder: (ctx, i) {
          final user = chatsToShow[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(user.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user.contactNo ?? ""),
            onTap: () => _openChat(user),
          );
        },
      )
          : ListView.separated(
        itemCount: _rooms.length,
        separatorBuilder: (_, __) => const Divider(height: 0.5),
        itemBuilder: (ctx, i) => _buildChatTile(_rooms[i]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          // Start new chat
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
