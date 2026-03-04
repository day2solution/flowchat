import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/screens/chat_list_screen.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flowchat/services/web_socket_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final MyAccount myAccount;
  final bool isNewProfile;

  const ProfileSetupScreen({
    required this.myAccount,
    required this.isNewProfile,
    super.key,
  });

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _aboutController;
  final ChatRepository _repo = ChatRepository();
  bool _isLoading = false;
  File? _imageFile;
  final primaryColor = const Color(0xFFFF7F50);
  final secondaryColor = const Color(0xFF6C63FF);
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.myAccount.name);
    _phoneController = TextEditingController(text: widget.myAccount.contactNo);
    _aboutController = TextEditingController(
      text: widget.myAccount.about ?? "Hey there! I'm using FlowChat",
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(primaryColor, secondaryColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildUniqueTextField(
                    label: "FULL NAME",
                    controller: _nameController,
                    icon: Icons.person_rounded,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 25),
                  _buildUniqueTextField(
                    label: "PHONE NUMBER",
                    controller: _phoneController,
                    icon: Icons.phone_iphone_rounded,
                    color: secondaryColor,
                    enabled: false,
                  ),
                  const SizedBox(height: 25),
                  _buildUniqueTextField(
                    label: "ABOUT ME",
                    controller: _aboutController,
                    icon: Icons.bubble_chart_rounded,
                    color: Colors.orange,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 50),
                  _buildSubmitButton(primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color1, Color color2) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Artistic Background Shape
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(80),
            ),
          ),
        ),
        // Decorative Circles for "Unique" look
        Positioned(
          top: -50,
          right: -50,
          child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1)),
        ),

        SafeArea(
          child: Column(
            children: [
              Text(
                widget.isNewProfile ? "Welcome!" : "Profile Settings",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              _buildAvatarPicker(color1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPicker(Color primaryColor) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
              ],
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : NetworkImage(
                "${Environment.hostApiUrl}/uploads/profiles/${widget.myAccount.contactNo}.gif",
              ) as ImageProvider,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color.withOpacity(0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: color),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFFFF4D4D)]),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          widget.isNewProfile ? "GET STARTED" : "SAVE CHANGES",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // Helper Methods (Keep your existing _pickImage and _submit logic here)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submit() async {
    // ... (Keep your existing validation and API call logic)
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your full name"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final dbAccount = MyAccount(
      contactNo: widget.myAccount.contactNo,
      name: name,
      about: _aboutController.text.trim(),
    );

    try {
      final fetchedAccount = await _repo.updateMyProfile(dbAccount, context);
      if (mounted) {
        WebSocketService().connect(dbAccount.contactNo);
        if (widget.isNewProfile) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatListScreen(myAccount: fetchedAccount ?? dbAccount)));
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}