import 'package:flowchat/config/Utility.dart';
import 'package:flowchat/config/typing_indicator.dart';
import 'package:flowchat/constant.dart';
import 'package:flowchat/models/ChatComposerModel.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/models/recent_chat.dart';
import 'package:flowchat/services/chat_db.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/chat_repository.dart';
import '../services/web_socket_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/composer.dart';

class ChatScreen extends StatefulWidget {
  final MyAccount myAccount;
  final User peer;

  const ChatScreen({
    required this.myAccount,
    required this.peer,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _repo = ChatRepository();
  List<ChatMessage> _messages = [];
  bool _peerTyping = false;

  @override
  void initState() {
    super.initState();
    _load();
    _repo.onIncoming(_handleIncoming);
    _repo.onMsgStatus(_handleStatusUpdate);
    WebSocketService().onTyping(_handleTyping);
  }

  void _handleIncoming(ChatMessage m) {
    if (!mounted) return;
    if (m.senderId == widget.peer.contactNo) {
      setState(() => _messages.add(m));
      _scrollToEnd();
      saveLastMessage(widget.peer.contactNo!, widget.peer.name, m.content, widget.myAccount.contactNo);
      WebSocketService().sendReadAck(m.id, m.senderId);
    }
  }

  void _handleStatusUpdate(String msgId, String status) {
    final index = _messages.indexWhere((m) => m.id == msgId);
    if (index != -1) {
      setState(() => _messages[index].status = status);
    }
  }

  void _handleTyping(String senderId) {
    if (!mounted || senderId != widget.peer.contactNo) return;
    setState(() => _peerTyping = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _peerTyping = false);
    });
  }

  Future<void> _load() async {
    final msgs = await _repo.loadMessages(widget.peer.contactNo ?? "");
    if (mounted) setState(() => _messages = msgs);
    _scrollToEnd();
  }

  void _send(ChatComposerModel model) {
    final isText = model.type == MessageType.text;
    _repo.sendText(
      widget.peer.contactNo ?? "",
      widget.myAccount.contactNo,
      model.message,
      widget.peer.contactNo ?? "",
    );
    saveLastMessage(
        widget.peer.contactNo!,
        widget.peer.name,
        isText ? model.message : "📷 Image",
        widget.peer.contactNo
    );
    _load();
  }

  void _onTyping() {
    if (widget.peer.contactNo != null) {
      WebSocketService().sendTyping(widget.peer.contactNo!);
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 75,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(peer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _peerTyping ? "typing..." : (peer.online ? "online" : "offline"),
                    style: TextStyle(
                      fontSize: 12,
                      color: _peerTyping || peer.online ? Colors.greenAccent : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_outlined, color: Colors.white)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined, color: Colors.white)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.white)),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD), // Soft background color
          image: DecorationImage(
            image: const AssetImage("assets/chat_bg.png"),
            opacity: 0.04, // Very faint pattern
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final isMe = m.senderId == widget.myAccount.contactNo;
                  return ChatBubble(msg: m, isMe: isMe);
                },
              ),
            ),
            if (_peerTyping)
            // --- Enhanced Typing Indicator with Animation ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _peerTyping
                    ? const Padding(
                  key: ValueKey('typing_indicator'),
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: TypingIndicator(),
                )
                    : const SizedBox.shrink(key: ValueKey('no_typing')),
              ),

            // Bottom Input Area with a "Floating" look
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(child: Composer(onSend: _send, onTyping: _onTyping)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User peer) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white24,
        child: ClipOval(
          child: Image.network(
            "${AppConstant.HOST}/uploads/profiles/${peer.contactNo!}.gif",
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Utility().getRandomColor(),
              alignment: Alignment.center,
              child: Text(
                  peer.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveLastMessage(String contactNo, String name, String msg, String? profileImage) async {
    final chat = RecentChat(
      contactNo: contactNo,
      name: name,
      lastMessage: msg,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      profileImage: profileImage,
    );
    await ChatDb().upsertChat(chat);
  }

  @override
  void dispose() {
    debugPrint("ChatScreen dispose");
    _scrollController.dispose();
    super.dispose();
  }
}