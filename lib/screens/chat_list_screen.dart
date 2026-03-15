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

  @override
  void initState() {
    super.initState();
    _repo.connectUser(widget.myAccount.contactNo);
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

  void _handleIncoming(ChatMessage message) async {
    if (!mounted) return;
    final isMe = message.senderId == widget.myAccount.contactNo;
    final isCurrentlyChatting = activeChatUser == message.senderId;

    if (!isMe && !isCurrentlyChatting) {
      String displayName = _getUserNameByContact(message.senderId);
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

  String _getUserNameByContact(String contactNo) {
    try {
      final user = _recentChats.firstWhere((u) => u.contactNo == contactNo);
      return user.name;
    } catch (e) {
      return contactNo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth > 600;

    final displayedUsers = _showSearch && _searchController.text.isNotEmpty
        ? _searchResults
        : _recentChats;

    return Scaffold(
      backgroundColor: isTablet ? const Color(0xFFF1F5F9) : Colors.white,
      appBar: AppBar(
        toolbarHeight: isTablet ? 100 : 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: _buildUniqueHeader(screenWidth, isTablet),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Container(
          // CONSTRAINT: Limits width on tablets for a professional look
          constraints: BoxConstraints(
            maxWidth: isTablet ? 700 : double.infinity,
          ),
          child: GestureDetector(
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      borderRadius: isTablet
                          ? const BorderRadius.vertical(
                              top: Radius.circular(30),
                            )
                          : null,
                    ),
                    child: _isSearching
                        ? Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          )
                        : (displayedUsers.isEmpty)
                        ? _buildEmptyState(screenWidth, screenHeight, isTablet)
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              top: 15,
                              bottom: 100,
                              left: isTablet ? 10 : 0,
                              right: isTablet ? 10 : 0,
                            ),
                            itemCount: displayedUsers.length,
                            itemBuilder: (ctx, i) {
                              return _buildSocialChatTile(
                                displayedUsers[i],
                                screenWidth,
                                isTablet,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFab(screenWidth, isTablet),
    );
  }

  Widget _buildUniqueHeader(double screenWidth, bool isTablet) {
    return Stack(
      children: [
        Container(
          height: isTablet ? 200 : screenWidth / 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -screenWidth / 10,
          left: -screenWidth / 10,
          child: CircleAvatar(
            radius: isTablet ? 120 : screenWidth / 5,
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : screenWidth / 20,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _showSearch
                    ? _buildSearchField(screenWidth, isTablet)
                    : Text(
                        "Messages",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet
                              ? 32
                              : ScreenUtil().getAdaptiveSize(context, 26),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                _buildHeaderActions(isTablet),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialChatTile(User user, double screenWidth, bool isTablet) {
    final lastMsg = user.lastMessage ?? "Say hi! 👋";
    final isImage = CommonUtil.isBase64(lastMsg);
    final double avatarRadius = isTablet
        ? 35
        : (screenWidth / 14).clamp(25.0, 35.0);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 15 : screenWidth / 25,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openChat(user),
        contentPadding: EdgeInsets.all(isTablet ? 15 : screenWidth / 35),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: NetworkImage(
                "${Environment.hostApiUrl}/uploads/profiles/${user.contactNo!}.gif",
              ),
            ),
            if (user.online)
              Positioned(
                right: 0,
                bottom: 0,
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
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isTablet ? 18 : ScreenUtil().getAdaptiveSize(context, 17),
          ),
        ),
        subtitle: Text(
          isImage ? "📷 Image" : lastMsg,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isTablet ? 15 : ScreenUtil().getAdaptiveSize(context, 14),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              user.timestamp != null
                  ? CommonUtil().formatTimestamp(user.timestamp!)
                  : "",
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                color: Colors.grey,
              ),
            ),
            if ((user.unreadCount ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
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

  Widget _buildSearchField(double screenWidth, bool isTablet) {
    return Expanded(
      child: Container(
        height: isTablet ? 60 : 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
              fontSize: isTablet ? 18 : 16,
            ),
            decoration: InputDecoration(
              hintText: 'Find friends...',
              counterText: "",
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.isNotEmpty) {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _searchUsers(query);
      });
    }
  }

  Future<void> _searchUsers(String query) async {
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

  Widget _buildFab(double screenWidth, bool isTablet) {
    return Container(
      height: isTablet ? 65 : 55,
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
        icon: Icon(
          Icons.add_comment_rounded,
          color: Colors.white,
          size: isTablet ? 28 : 24,
        ),
        label: Text(
          "NEW CHAT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: isTablet ? 16 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: isTablet ? 150 : 80,
            color: primaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            "No Conversations",
            style: TextStyle(
              fontSize: isTablet ? 28 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(bool isTablet) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: Colors.white,
            size: isTablet ? 30 : 24,
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
            size: isTablet ? 30 : 24,
          ),
          onSelected: (val) => _handleMenuSelection(val),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: "settings",
              child: Text("Profile Settings"),
            ),
            const PopupMenuItem(value: "refresh", child: Text("Delete Chats")),
            const PopupMenuItem(
              value: "logout",
              child: Text("Logout", style: TextStyle(color: Colors.red)),
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
      // Inside ChatListScreen logout logic
      _repo.clearMyAccount();
      _repo.disconnect();

      // Navigate back to ChatApp, which will now re-run _checkAndSetAccount
      // and find no account, showing the AuthScreen.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ChatApp()),
        (route) => false,
      );
    } else if (value == 'refresh') {
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
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'chat_messages_channel',
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      message.id.hashCode,
      displayName,
      message.content,
      platformChannelSpecifics,
    );
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
