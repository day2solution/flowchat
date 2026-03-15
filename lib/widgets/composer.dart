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

  // Theme Colors
  final Color coralColor = const Color(0xFFFF7F50);
  final Color purpleColor = const Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    // 1. Detect Screen Type
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.only(
          left: isTablet ? 20 : 10,
          right: isTablet ? 20 : 10,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 25 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Plus Action (Scales for Tablet)
                _buildRoundAction(
                  icon: Icons.add_rounded,
                  color: purpleColor,
                  onTap: () => _showAttachmentSheet(context, isTablet),
                  isTablet: isTablet,
                ),

                const SizedBox(width: 8),

                // 2. Input Field Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6F9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            minLines: 1,
                            maxLines: 5,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16, // Scaled Font
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() => _isTyping = value.trim().isNotEmpty);
                              widget.onTyping?.call();
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt_outlined,
                              color: Colors.grey,
                              size: isTablet ? 26 : 22 // Scaled Icon
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Send/Mic Button (Scales for Tablet)
                GestureDetector(
                  onTap: _handleSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isTablet ? 56 : 48, // Taller for tablets
                    width: isTablet ? 56 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isTyping
                            ? [coralColor, const Color(0xFFFF4D4D)]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isTyping ? coralColor : Colors.grey).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      _isTyping ? Icons.send_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: isTablet ? 26 : 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: isTablet ? 56 : 48,
        width: isTablet ? 56 : 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: color, size: isTablet ? 30 : 26),
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

  void _showAttachmentSheet(BuildContext context, bool isTablet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center( // Centers the sheet content for tablet
        child: Container(
          constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachmentItem(Icons.image_rounded, "Gallery", Colors.purple, () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  }, isTablet),
                  _attachmentItem(Icons.location_on_rounded, "Location", Colors.green, () {}, isTablet),
                  _attachmentItem(Icons.person_rounded, "Contact", Colors.orange, () {}, isTablet),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentItem(IconData icon, String label, Color color, VoidCallback onTap, bool isTablet) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: isTablet ? 75 : 60,
            width: isTablet ? 75 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 34 : 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold
        )),
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