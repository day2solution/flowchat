import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flowchat/config/Constant.dart';
import 'package:flowchat/models/ChatComposerModel.dart';
import 'package:flowchat/util/CommonUtil.dart';

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

  // Unified Theme Colors
  final Color coralColor = const Color(0xFFFF7F50);
  final Color purpleColor = const Color(0xFF6C63FF);
  final Color gradientEnd = const Color(0xFFFF4D4D);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 12,
        bottom: bottomPadding > 0 ? bottomPadding + 10 : 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Plus Action (Purple Tinted Squircle)
              _buildPlusButton(),

              const SizedBox(width: 10),

              // 2. Neumorphic-Style Input Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87
                          ),
                          decoration: InputDecoration(
                            hintText: 'Share something...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() => _isTyping = value.trim().isNotEmpty);
                            widget.onTyping?.call();
                          },
                        ),
                      ),
                      _buildCameraAction(),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 3. Animated Send/Mic Button (Matches Profile Submit Button)
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlusButton() {
    return InkWell(
      onTap: () => _showAttachmentSheet(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: purpleColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.add_rounded, color: purpleColor, size: 28),
      ),
    );
  }

  Widget _buildCameraAction() {
    return IconButton(
      icon: Icon(Icons.camera_enhance_rounded, color: Colors.grey.shade400, size: 22),
      onPressed: () => _pickImage(ImageSource.camera),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _handleSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isTyping
                ? [coralColor, gradientEnd]
                : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isTyping ? coralColor : Colors.grey).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Icon(
          _isTyping ? Icons.send_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  void _handleSend() {
    if (_isTyping) {
      final text = _ctrl.text.trim();
      if (text.isNotEmpty) {
        widget.onSend(ChatComposerModel(type: MessageType.text, message: text));
        _ctrl.clear();
        setState(() => _isTyping = false);
      }
    }
  }

  void _showAttachmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentItem(Icons.image_rounded, "Gallery", Colors.purple, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                }),
                _attachmentItem(Icons.location_on_rounded, "Location", Colors.green, () {}),
                _attachmentItem(Icons.person_rounded, "Contact", Colors.orange, () {}),
                _attachmentItem(Icons.folder_copy_rounded, "Files", Colors.blue, () {}),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _attachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 64, width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade700)
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File compressed = await CommonUtil.compressImage(File(pickedFile.path));
      String base64String = base64Encode(await compressed.readAsBytes());
      widget.onSend(ChatComposerModel(
        type: MessageType.image,
        message: Constant.IMAGE_PREFIX + base64String,
      ));
    }
  }
}