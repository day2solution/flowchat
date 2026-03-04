import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/config/typing_indicator.dart';
import 'package:flowchat/models/ChatComposerModel.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/models/recent_chat.dart';
import 'package:flowchat/services/chat_db.dart';
import 'package:flowchat/util/CommonUtil.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/chat_repository.dart';
import '../services/web_socket_service.dart';
import '../widgets/composer.dart';

class ChatScreen extends StatefulWidget {
  final MyAccount myAccount;
  final User peer;

  const ChatScreen({required this.myAccount, required this.peer, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _repo = ChatRepository();
  List<ChatMessage> _messages = [];
  bool _peerTyping = false;
  static double? screenWidth;
  static double? screenHeight;
  static MediaQueryData? _mediaQueryData;

  // --- Theme Colors from Profile/Composer ---
  final Color coralColor = const Color(0xFFFF7F50);
  final Color purpleColor = const Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    _loadMessages();
    _repo.onIncoming(_handleIncoming);
    _repo.onMsgStatus(_handleStatusUpdate);
    WebSocketService().onTyping(_handleTyping);
  }

  // --- Logic Implementations ---

  Future<void> _loadMessages() async {
    final msgs = await _repo.loadMessages(widget.peer.contactNo ?? "");
    if (mounted) setState(() => _messages = msgs);
  }

  void _handleIncoming(ChatMessage m) {
    if (!mounted || m.senderId != widget.peer.contactNo) return;
    setState(() => _messages.add(m));
    _saveToRecent(m.content);
    WebSocketService().sendReadAck(m.id, m.senderId);
  }

  void _handleStatusUpdate(String msgId, String status) {
    if (!mounted) return;
    final index = _messages.indexWhere((m) => m.id == msgId);
    if (index != -1) setState(() => _messages[index].status = status);
  }

  void _handleTyping(String senderId) {
    if (!mounted || senderId != widget.peer.contactNo) return;
    setState(() => _peerTyping = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _peerTyping = false);
    });
  }

  void _send(ChatComposerModel model) {
    final isText = model.type == MessageType.text;
    _repo.sendText(
      widget.peer.contactNo ?? "",
      widget.myAccount.contactNo,
      model.message,
      widget.peer.contactNo ?? "",
    );
    _saveToRecent(isText ? model.message : "📷 Image");
    _loadMessages(); // Refresh to show the message sent locally
  }

  void _saveToRecent(String lastMsg) async {
    final chat = RecentChat(
      contactNo: widget.peer.contactNo!,
      name: widget.peer.name,
      lastMessage: lastMsg,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      profileImage: widget.peer.contactNo,
    );
    await ChatDb().upsertChat(chat);
  }

  void _onTyping() {
    if (widget.peer.contactNo != null) {
      WebSocketService().sendTyping(widget.peer.contactNo!);
    }
  }

  @override
  Widget build(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: screenWidth! / 6,
        backgroundColor: Colors.transparent,
        flexibleSpace: _buildUniqueHeader(),
        automaticallyImplyLeading: false,
      ),

      body: Column(
        children: [
          // _buildUniqueHeader(),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FD),
              // Soft background matching Profile
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                // Key for chat: latest message at bottom
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth!/40,
                  vertical: screenWidth!/70,
                ),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final message = _messages[_messages.length - 1 - i];
                  return _buildSocialMessageBubble(message);
                },
              ),
            ),
          ),
          if (_peerTyping)
            Padding(
              padding: EdgeInsets.only(left: screenWidth!/80, bottom: screenWidth!/100),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(),
              ),
            ),
          // Integrating your custom Composer
          Composer(onSend: _send, onTyping: _onTyping),
        ],
      ),
    );
  }

  Widget _buildUniqueHeader() {
    return Stack(
      children: [
        Container(
          height: screenWidth! / 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [purpleColor, coralColor], // Profile screen combination
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -30,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                _buildHeaderAvatar(),
                const SizedBox(width: 15),
                _buildHeaderTitle(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: NetworkImage(
          "${Environment.hostApiUrl}/uploads/profiles/${widget.peer.contactNo!}.gif",
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.peer.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            _peerTyping
                ? "typing..."
                : (widget.peer.online ? "Online" : "Offline"),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMessageBubble(ChatMessage message) {
    final bool isMe = message.senderId == widget.myAccount.contactNo;
    final bool isImage = CommonUtil.isBase64(message.content);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: isImage
                ? const EdgeInsets.all(5)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              // SENDER: Matches your Composer/Profile Button Gradient
              // RECEIVER: Matches Profile Input Field (White)
              gradient: isMe
                  ? LinearGradient(
                      colors: [coralColor, const Color(0xFFFF4D4D)],
                    )
                  : null,
              color: isMe ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isMe ? 22 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 22),
              ),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? coralColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: isImage
                      ? () => showImageDialog(
                          message.content,
                          "Photo",
                          context,
                          "image",
                        )
                      : null,
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CommonUtil.getImage(message.content, context),
                        )
                      : Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          message.timestamp.millisecond,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isMe) const SizedBox(width: 4),
                    _buildStatusIcon(message.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showImageDialog(
    String imagePath,
    String? imageName,
    BuildContext context,
    String fileType,
  ) {
    showDialog(
      context: context,
      // use rootNavigator to ensure it sits on top of everything
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        // Rename context to dialogContext
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        // Make it full screen for better viewing
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Zoomable Image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CommonUtil.getImageInDialogue(imagePath, dialogContext),
            ),

            // 2. Stylish Close Button (Top Right)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  // ✅ Use dialogContext to specifically pop the Dialog
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),

            // 3. Optional: Image Label (Bottom)
            if (imageName != null)
              Positioned(
                bottom: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    imageName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    final Color readColor = Colors.blueGrey;

    switch (status) {
      case 'SENT':
        return Icon(Icons.done_rounded, size: 14, color: Colors.white70);
      case 'DELIVERED':
        return Icon(Icons.done_all_rounded, size: 14, color: Colors.white70);
      case 'READ':
        return Icon(Icons.done_all_rounded, size: 14, color: readColor);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
