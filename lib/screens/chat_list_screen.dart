import 'dart:convert';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/constant.dart';
import 'package:flowchat/main.dart';
import 'package:flowchat/models/chat_message.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/screens/profile_setup_screen.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flowchat/util/CommonUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'chat_screen.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  final MyAccount myAccount;
  const ChatListScreen({required this.myAccount, super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _rooms = <ChatRoom>[];
  final TextEditingController _searchController = TextEditingController();
  final ChatRepository _repo = ChatRepository();
  List<User> _searchResults = [];
  List<User> _recentChats = [];
  bool _isSearching = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _repo.onUserPresence(_handlePresence);
    _repo.onIncoming(_handleIncoming);
    _repo.saveMyAccount(widget.myAccount);
    _loadRecentChats();
  }

  void _handleIncoming(ChatMessage message) async {
    if (!mounted) return;
    if (message.senderId != widget.myAccount.contactNo) {
      showNotification(message);
      _loadRecentChats();
    }
  }

  Future<void> _loadRecentChats() async {
    final chatList = await _repo.getRecentChats();
    setState(() => _recentChats = chatList.cast<User>());
    // _buildChatTile(user);
  }

  void _handlePresence(String userId, bool status) {
    if (!mounted) return;
    final index = _recentChats.indexWhere((m) => m.contactNo == userId);
    if (index != -1) {
      setState(() {
        _recentChats[index].online = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineUsers = _recentChats.where((u) => u.online == true).toList();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: _showSearch
            ? _buildSearchField()
            : Text(
          "Messages",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        actions: _buildAppBarActions(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_showSearch) setState(() => _showSearch = false);
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // --- 1. Horizontal Online Friends (Social Feature) ---
            if (!_showSearch && onlineUsers.isNotEmpty) _buildOnlineBar(onlineUsers),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _recentChats.isEmpty && _searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 15, bottom: 80),
                  itemCount: _searchResults.isNotEmpty ? _searchResults.length : _recentChats.length,
                  itemBuilder: (ctx, i) {
                    final user = _searchResults.isNotEmpty ? _searchResults[i] : _recentChats[i];
                    return _buildChatTile(user);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showSearch = true),
        backgroundColor: primaryColor,
        elevation: 4,

        // shadowColor: primaryColor.withOpacity(0.4),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: const Text("New Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOnlineBar(List<User> users) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: users.length,
        itemBuilder: (ctx, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Colors.orange, Colors.pinkAccent]),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage("${AppConstant.HOST}/uploads/profiles/${users[i].contactNo!}.gif"),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Text(users[i].name.split(' ')[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTile(User user) {
    final lastMessage = (user.lastMessage?.isNotEmpty ?? false) ? user.lastMessage! : "Say hi! 👋";
    final time = (user.timestamp == null || user.timestamp!.isNaN) ? "" : formatTimestamp(user.timestamp!);

    return ListTile(
      onTap: () => _openChat(user),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: NetworkImage("${AppConstant.HOST}/uploads/profiles/${user.contactNo!}.gif"),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                CommonUtil.isBase64(lastMessage) ? "📷 Image" : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            if (user.unreadCount != null && user.unreadCount! > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                child: Text("${user.unreadCount}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Search friends...', border: InputBorder.none, icon: Icon(Icons.search)),
        onChanged: _searchUsers,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network('https://cdn-icons-png.flaticon.com/512/6598/6598519.png', height: 150, opacity: const AlwaysStoppedAnimation(0.5)),
          const SizedBox(height: 20),
          const Text("No chats yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text("Find some friends to start the party!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- Helpers & Search (Keep Logic same as your original) ---

  List<Widget> _buildAppBarActions() {
    if (_showSearch) return [IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => setState(() { _showSearch = false; _searchResults.clear(); _searchController.clear(); }))];
    return [
      IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () => setState(() => _showSearch = true)),
      PopupMenuButton<String>(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onSelected: (value) {
          switch (value) {
            case 'settings':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSetupScreen(myAccount: widget.myAccount,isNewProfile: false,),
                ),
              );
              break;
            case 'refresh':
              _loadRecentChats();
              break;
            case 'delete_chats':
              clearRecentChats();
              _loadRecentChats();
              break;
            case 'logout':
              _repo.clearMyAccount();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const ChatApp()),
                    (Route<dynamic> route) => false,
              );
              break;
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: "settings", child: Text("Settings")),
          const PopupMenuItem(value: "refresh", child: Text("refresh")),
          const PopupMenuItem(value: "logout", child: Text("Logout", style: TextStyle(color: Colors.red)))
        ],
      )
    ];
  }

  // void _openChat(User peer) {
  //   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(myAccount: widget.myAccount, peer: peer)));
  //   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(myAccount: widget.myAccount, peer: peer)));
  // }
  void _openChat(User peer) async {
    // ... existing code to find/create room ...

    // 1. Wait for the result of the navigation
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          myAccount: widget.myAccount,
          peer: peer,
        ),
      ),
    );

    // 2. This code runs only AFTER ChatScreen is disposed/popped
    debugPrint("User returned from ChatScreen with ${peer.name}");
    // Refresh your list here if needed
    _loadRecentChats();
  }
  String formatTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) return DateFormat('hh:mm a').format(dateTime);
    if (now.difference(dateTime).inDays == 1) return "Yesterday";
    return DateFormat('dd/MM/yy').format(dateTime);
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);
    try {
      final response = await http.get(Uri.parse('${Environment.hostApiUrl}/api/users/search?query=$query'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _searchResults = data.map((e) => User.fromJson(e)).toList());
      }
    } catch (e) { debugPrint("Error: $e"); }
    finally { setState(() => _isSearching = false); }
  }

  Future<void> showNotification(ChatMessage message) async {
    debugPrint("🔔 Attempting to show notification for: ${message.senderId}");

    // Define High Importance Android Settings
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'chat_messages_channel', // Unique ID
      'Chat Messages',         // Channel Name (visible in phone settings)
      channelDescription: 'Notifications for new friendship chats',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      ticker: 'ticker',
      // Optional: Add a custom sound or vibration pattern if desired
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Identify if the content is an image or text
    String notificationBody = CommonUtil.isBase64(message.content)
        ? "📷 Sent an image"
        : (message.content ?? "You have a new message");

    try {
      await flutterLocalNotificationsPlugin.show(
        message.id.hashCode, // Unique ID for each notification so they don't overwrite
        message.senderId ?? "New Message",
        notificationBody,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint("❌ Notification Error: $e");
    }
  }

  Future<void> clearRecentChats() async { await _repo.clearRecentChats(); }
}