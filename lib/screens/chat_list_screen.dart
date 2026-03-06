import 'dart:async';
import 'dart:convert';
import 'package:flowchat/config/app_style.dart';
import 'package:flowchat/main.dart';
import 'package:flowchat/util/ScreenUtil.dart';
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

  final Color primaryColor = AppStyle.primaryColor;
  final Color secondaryColor = AppStyle.secondaryColor;
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
        _repo.updateUserOnlineStatus(userId, status);
      });
    }
  }

  String getUserNameByContact(String contactNo) {
    try {
      final user = _recentChats.firstWhere((u) => u.contactNo == contactNo);
      return user.name;
    } catch (e) {
      return contactNo;
    }
  }

  void _handleIncoming(ChatMessage message) async {
    if (!mounted) return;

    final isMe = message.senderId == widget.myAccount.contactNo;
    final isCurrentlyChatting = activeChatUser == message.senderId;

    if (!isMe && !isCurrentlyChatting) {
      String displayName = getUserNameByContact(message.senderId);
      await saveLastMessage(
        message.senderId,
        displayName,
        message.content,
        message.senderId,
      );
      await showNotification(message, displayName);
      _loadRecentChats();
    }
  }

  @override
  Widget build(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;

    // Calculate responsive horizontal padding for the whole list
    final horizontalPadding = screenWidth! / 25;

    final displayedUsers = _showSearch && _searchController.text.isNotEmpty
        ? _searchResults
        : _recentChats;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Responsive AppBar height based on width
        // toolbarHeight: (screenHeight! / 5).clamp(70.0, 100.0),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            Expanded(
              child: Container(
                color: const Color(0xFFF8F9FD),
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : displayedUsers.isEmpty
                    ? SingleChildScrollView(child: _buildEmptyState())
                    : ListView.builder(
                        // Responsive bottom padding for FAB clearance
                        padding: EdgeInsets.only(
                          top: 10,
                          bottom: screenHeight! / 8,
                        ),
                        itemCount: displayedUsers.length,
                        itemBuilder: (ctx, i) {
                          return _buildSocialChatTile(
                            displayedUsers[i],
                            screenWidth,
                          );
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
        Container(
          height: screenWidth! / 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -screenWidth! / 10,
          left: -screenWidth! / 10,
          child: CircleAvatar(
            radius: screenWidth! / 5,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        SafeArea(
          child: Padding(
            // Responsive horizontal padding
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth! / 20,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _showSearch
                    ? _buildSearchField()
                    : Text(
                        "Messages",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenUtil().getAdaptiveSize(context, 16),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                _buildHeaderActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialChatTile(User user, double? screenWidth) {
    final lastMsg = user.lastMessage ?? "Say hi! 👋";
    final isImage = CommonUtil.isBase64(lastMsg);
    // Dynamic Avatar Size
    final double avatarRadius = (screenWidth! / 14).clamp(25.0, 35.0);

    return Container(
      // Responsive margins
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth / 25,
        vertical: screenHeight! / 120,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openChat(user),
        contentPadding: EdgeInsets.all(screenWidth / 35),
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
                radius: avatarRadius,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: NetworkImage(
                  "${Environment.hostApiUrl}/uploads/profiles/${user.contactNo!}.gif",
                ),
                onBackgroundImageError: (_, __) =>
                    Logger.log("chat_list_screen", "Image error"),
              ),
            ),
            if (user.online)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: avatarRadius / 2,
                  height: avatarRadius / 2,
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
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: ScreenUtil().getAdaptiveSize(context, 17),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isImage ? "📷 Image" : lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: ScreenUtil().getAdaptiveSize(context, 14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              user.timestamp != null
                  ? CommonUtil().formatTimestamp(user.timestamp ?? 0)
                  : "",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: ScreenUtil().getAdaptiveSize(context, 11),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ScreenUtil().getAdaptiveSize(context, 10),
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
        height: (screenWidth! / 8).clamp(45.0, 55.0),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white, // Solid white for better readability in search
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: TextField(
            controller: _searchController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofocus: true,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: ScreenUtil().getAdaptiveSize(context, 16),
            ),
            decoration: InputDecoration(
              hintText: 'Find friends...',
              counterText: "",
              isDense: true,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      height: (screenWidth! / 7).clamp(50.0, 65.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFFFF4D4D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => setState(() => _showSearch = true),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(
          Icons.add_comment_rounded,
          color: Colors.white,
          size: ScreenUtil().getAdaptiveSize(context, 20),
        ),
        label: Text(
          "NEW CHAT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: ScreenUtil().getAdaptiveSize(context, 10),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      // Centers the empty state in the middle of the remaining screen height
      height: screenHeight! - (screenWidth! / 3) - 100,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: screenWidth! / 4,
            color: primaryColor.withValues(alpha: 0.2),
          ),
          SizedBox(height: screenHeight! / 40),
          Text(
            "No Conversations",
            style: TextStyle(
              fontSize: ScreenUtil().getAdaptiveSize(context, 24),
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a chat with your friends!",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: ScreenUtil().getAdaptiveSize(context, 14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            size: ScreenUtil().getAdaptiveSize(context, 18),
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
          icon: Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
            size: ScreenUtil().getAdaptiveSize(context, 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (value) => _handleMenuSelection(value),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: "settings",
              child: Text(
                "Profile Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ScreenUtil().getAdaptiveSize(context, 10),
                ),
              ),
            ),
            PopupMenuItem(
              value: "refresh",
              child: Text(
                "Delete Chats",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ScreenUtil().getAdaptiveSize(context, 10),
                ),
              ),
            ),
            PopupMenuItem(
              value: "logout",
              child: Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: ScreenUtil().getAdaptiveSize(context, 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) async {
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
      await _repo.clearMyAccount();
      await _repo.clearRecentChats();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChatApp()),
        (route) => false,
      );
    } else if (value == 'refresh') {
      // _de
      _repo.clearRecentChats();
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
        : (message.content);

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
    if (query.isNotEmpty && query != widget.myAccount.contactNo) {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _searchUsers(query);
      });
    }
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
      online: true,
    );
    await ChatDb().upsertChat(chat);
  }
}
