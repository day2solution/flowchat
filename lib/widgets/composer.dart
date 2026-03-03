import 'dart:convert';
import 'dart:io';

import 'package:flowchat/config/Constant.dart';
import 'package:flowchat/config/Logger.dart';
import 'package:flowchat/constant.dart';
import 'package:flowchat/models/ChatComposerModel.dart';
import 'package:flowchat/models/chat_message.dart';
import 'package:flowchat/util/CommonUtil.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class Composer extends StatefulWidget {
  final void Function(ChatComposerModel) onSend;
  final void Function()? onTyping;

  const Composer({required this.onSend, this.onTyping, super.key});

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _ctrl = TextEditingController();
  bool _isTyping = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Action: Emoji/Plus
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 28),
            onPressed: () => _showAttachmentSheet(context),
            visualDensity: VisualDensity.compact,
          ),

          // Message Input Field
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() => _isTyping = value.trim().isNotEmpty);
                        widget.onTyping?.call();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600, size: 22),
                    onPressed: () => _pickImage(ImageSource.camera),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Action: Send or Mic
          GestureDetector(
            onTap: _handleSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                _isTyping ? Icons.send_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    if (_isTyping) {
      final text = _ctrl.text.trim();
      if (text.isNotEmpty) {
        widget.onSend(ChatComposerModel(
          type: MessageType.text,
          message: text,
        ));
        _ctrl.clear();
        setState(() => _isTyping = false);
      }
    } else {
      // Logic for voice recording
      debugPrint("Voice recording started");
    }
  }

  // Social Friendship Style: Bottom Sheet for attachments
  void _showAttachmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachmentItem(Icons.image_rounded, "Gallery", Colors.purple, () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  }),
                  _attachmentItem(Icons.insert_drive_file_rounded, "Document", Colors.blue, () {}),
                  _attachmentItem(Icons.location_on_rounded, "Location", Colors.green, () {}),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      sendImage(imageFile);
    }
  }

  Future<void> sendImage(File imageFile) async {
    File compressed = await CommonUtil.compressImage(imageFile);
    List<int> imageBytes = await compressed.readAsBytes();
    String base64String = base64Encode(imageBytes);

    widget.onSend(ChatComposerModel(
      type: MessageType.image,
      message: Constant.IMAGE_PREFIX + base64String,
    ));
  }
}