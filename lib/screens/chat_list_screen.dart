import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flowchat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flowchat/config/Logger.dart';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/models/chat_message.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/models/recent_chat.dart';
import 'package:flowchat/models/user.dart';
import 'package:flowchat/services/chat_db.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flowchat/util/CommonUtil.dart';
import 'package:flowchat/screens/chat_screen.dart';
import 'package:flowchat/screens/profile_setup_screen.dart';

class ChatListScreen extends StatefulWidget {
  final MyAccount myAccount;

  const ChatListScreen({required this.myAccount, super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatRepository _repo = ChatRepository();

  List<User> _searchResults = [];
  List<User> _recentChats = [];
  bool _isSearching = false;
  bool _showSearch = false;
  String activeChatUser = "";
  Timer? _searchDebounce;

  // Theme Colors (Matching your Unique Design)
  final Color primaryColor = const Color(0xFFFF7F50); // Coral
  final Color secondaryColor = const Color(0xFF6C63FF); // Purple-Blue
  static double? screenWidth;
  static double? screenHeight;
  static MediaQueryData? _mediaQueryData;
  @override
  void initState() {
    super.initState();
    _repo.onUserPresence(_handlePresence);
    _repo.onIncoming(_handleIncoming);
    _repo.saveMyAccount(widget.myAccount);
    _loadRecentChats();
  }

  Future<void> _loadRecentChats() async {
    final chatList = await _repo.getRecentChats();
    if (!mounted) return;
    setState(() => _recentChats = List<User>.from(chatList));
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

  String getUserNameByContact(String contactNo) {
    try {
      // Search the recent chats list for a matching contact number
      final user = _recentChats.firstWhere((u) => u.contactNo == contactNo);
      return user.name;
    } catch (e) {
      // If no user is found with that contact number, return the number itself or "Unknown"
      return contactNo;
    }
  }

  void _handleIncoming(ChatMessage message) async {
    if (!mounted) return;

    final isMe = message.senderId == widget.myAccount.contactNo;
    final isCurrentlyChatting = activeChatUser == message.senderId;

    if (!isMe && !isCurrentlyChatting) {
      String displayName = getUserNameByContact(message.senderId ?? "");
      saveLastMessage(
        message.senderId,
        displayName,
        message.content,
        message.senderId,
      );
      showNotification(message, displayName);
      _loadRecentChats();
    }
  }

  // ... (Keep logic: _handleIncoming, _loadRecentChats, _handlePresence, _onSearchChanged, _searchUsers identical)

  @override
  Widget build(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    final displayedUsers = _showSearch && _searchController.text.isNotEmpty
        ? _searchResults
        : _recentChats;

    return Scaffold(
      backgroundColor: Colors.white,
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: screenWidth!/5,
        backgroundColor: Colors.transparent,
        flexibleSpace: _buildUniqueHeader(),
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () {
          if (_showSearch) {
            setState(() {
              _showSearch = false;
              _searchResults.clear();
              _searchController.clear();
            });
          }
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // _buildUniqueHeader(),
            Expanded(
              child: Container(
                color: const Color(0xFFF8F9FD), // Soft background
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 100),
                        itemCount: displayedUsers.isEmpty
                            ? 1
                            : displayedUsers.length,
                        itemBuilder: (ctx, i) {
                          if (displayedUsers.isEmpty) return _buildEmptyState();
                          return _buildSocialChatTile(displayedUsers[i]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildUniqueHeader() {
    return Stack(
      children: [
        // 1. Artistic Gradient Header (Matches Profile Screen)
        Container(
          height: screenWidth!/3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60)),
          ),
        ),
        // 2. Decorative Circle
        Positioned(
          top: -40,
          left: -40,
          child: CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
        // 3. Header Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 10, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _showSearch
                        ? _buildSearchField()
                        : const Text(
                            "Messages",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                    _buildHeaderActions(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialChatTile(User user) {
    final lastMsg = user.lastMessage ?? "Say hi! 👋";
    final isImage = CommonUtil.isBase64(lastMsg);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22), // Unique Squircular look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openChat(user),
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: user.online ? Colors.greenAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: NetworkImage(
                  "${Environment.hostApiUrl}/uploads/profiles/${user.contactNo!}.gif",
                ),
                onBackgroundImageError: (exception, stackTrace) => {
                  Logger.log("chat_list_screen", "image not found")
                },
              ),
            ),
            if (user.online)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isImage ? "📷 Image" : lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CommonUtil().formatTimestamp(user.timestamp ?? 0),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            if ((user.unreadCount ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, Colors.redAccent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${user.unreadCount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Expanded(
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Find friends...',
            hintStyle: TextStyle(color: primaryColor),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchController.clear();
              _searchResults.clear();
            }
          }),
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: Colors.white,
            size: 30,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (value) => _handleMenuSelection(value),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: "settings",
              child: Text(
                "Profile Settings",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const PopupMenuItem(value: "refresh", child: Text("Refresh Chats")),
            const PopupMenuItem(
              value: "logout",
              child: Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFFFF4D4D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => setState(() => _showSearch = true),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          "NEW CHAT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  void _handleMenuSelection(String value) {
    if (value == 'settings') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            myAccount: widget.myAccount,
            isNewProfile: false,
          ),
        ),
      );
    } else if (value == 'logout') {
      _repo.clearMyAccount();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChatApp()),
        (route) => false,
      );
    } else if (value == 'refresh') {
      _loadRecentChats();
    }
  }

  void _openChat(User peer) async {
    setState(() => activeChatUser = peer.contactNo!);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(myAccount: widget.myAccount, peer: peer),
      ),
    );
    setState(() => activeChatUser = "");
    _loadRecentChats();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 100,
            color: primaryColor.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            "No Conversations",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a chat with your friends!",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showNotification(ChatMessage message, String displayName) async {
    Logger.log(
      "chat_list_screen",
      "🔔 Attempting to show notification for: ${message.senderId}",
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_messages_channel',
          'Chat Messages',
          channelDescription: 'Notifications for new friendship chats',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          ticker: 'ticker',
          enableVibration: true,
          playSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String notificationBody = CommonUtil.isBase64(message.content)
        ? "📷 Sent an image"
        : (message.content ?? "You have a new message");

    try {
      await flutterLocalNotificationsPlugin.show(
        message.id.hashCode,
        displayName,
        notificationBody,
        platformChannelSpecifics,
      );
    } catch (e) {
      Logger.log("chat_list_screen", "❌ Notification Error: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.parse('${Environment.hostApiUrl}/api/users/search?query=$query'),
      );
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        setState(
          () => _searchResults = data.map((e) => User.fromJson(e)).toList(),
        );
      }
    } catch (e) {
      Logger.log("chat_list_screen", "Search Error: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> saveLastMessage(
    String contactNo,
    String name,
    String msg,
    String? profileImage,
  ) async {
    final chat = RecentChat(
      contactNo: contactNo,
      name: name,
      lastMessage: msg,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      profileImage: profileImage,
    );
    await ChatDb().upsertChat(chat);
  }
}
