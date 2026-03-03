import 'package:flowchat/util/CommonUtil.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;

  const ChatBubble({required this.msg, required this.isMe, super.key});

  @override
  Widget build(BuildContext context) {
    // Modern colors: Light primary for "me", White for "peer"
    // Using a subtle green/primary variant for isMe
    final bubbleColor = isMe ? const Color(0xFFE7FFDB) : Colors.white;
    final align = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    // Asymmetric rounding: The corner pointing to the sender is sharpened
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    bool isImage = CommonUtil.isBase64(msg.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: align,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Message Content
                  Padding(
                    padding: isImage
                        ? const EdgeInsets.all(3) // Edge-to-edge look for images
                        : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: _buildContent(context),
                  ),

                  // 2. Metadata (Time + Status)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4, left: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTimestamp(msg.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(msg.status),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (CommonUtil.isBase64(msg.content)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: GestureDetector(
          onTap: () => showImageDialog(msg.content, null, context, "image"),
          child: CommonUtil.getImage(msg.content, context),
        ),
      );
    } else {
      return Text(
        msg.content,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15.5,
          height: 1.2,
        ),
      );
    }
  }

  void showImageDialog(String imagePath, String? imageName, BuildContext context, String fileType) {
    showDialog(
      context: context,
      // use rootNavigator to ensure it sits on top of everything
      useRootNavigator: true,
      builder: (dialogContext) => Dialog( // Rename context to dialogContext
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Make it full screen for better viewing
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
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    imageName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(DateTime dateTime) {
    // Assuming the DB stores UTC, convert to local
    return DateFormat('hh:mm a').format(dateTime.toLocal());
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'SENT':
        return const Icon(Icons.check, size: 13, color: Colors.grey);
      case 'DELIVERED':
        return const Icon(Icons.done_all, size: 13, color: Colors.grey);
      case 'READ':
        return const Icon(Icons.done_all, size: 13, color: Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }
}