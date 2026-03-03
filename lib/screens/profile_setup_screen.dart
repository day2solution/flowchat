import 'dart:io';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/constant.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/screens/chat_list_screen.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flowchat/services/web_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added for actual image picking

class ProfileSetupScreen extends StatefulWidget {
  final MyAccount myAccount;
  final bool isNewProfile;

  const ProfileSetupScreen({required this.myAccount,required this.isNewProfile, super.key});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  final ChatRepository _repo = ChatRepository();
  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.myAccount.name);
    _aboutController = TextEditingController(text: widget.myAccount.about ?? "Available");

  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final about = _aboutController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dbAccount = MyAccount(contactNo: widget.myAccount.contactNo, name: name, about: about);

    try {
      // Pass the image to your repository if your API supports it
      final fetchedAccount = await _repo.updateMyProfile(dbAccount, context);

      if (mounted) {
        WebSocketService().connect(dbAccount.contactNo);
        setState(() => _isLoading = false);

        widget.isNewProfile? Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatListScreen(myAccount: fetchedAccount ?? dbAccount),
          ),
        ): Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Very light cool grey
      body: Stack(
        children: [
          // 1. Background Gradient Header
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Create Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Let your friends know who you are!",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // 2. Profile Image Card
                  _buildProfileCard(primaryColor),

                  const SizedBox(height: 24),

                  // 3. Inputs Card
                  _buildInputCard(primaryColor),

                  const SizedBox(height: 32),

                  // 4. Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Start Chatting",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade100,
                    onBackgroundImageError: _imageFile == null ? (ext, stack) {
                      // You don't need to do anything here, the 'child' below will be shown
                    } : null,
                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) :  NetworkImage("${Environment.hostApiUrl}/uploads/profiles/${widget.myAccount.contactNo}.gif") as ImageProvider,
                    child: _imageFile == null
                        ? Icon(Icons.person_add_rounded, size: 50, color: primaryColor.withOpacity(0.5))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Tap to change photo",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Display Name"),
          _buildTextField(
            controller: _nameController,
            hint: "How should friends call you?",
            icon: Icons.person_outline,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 20),
          _buildLabel("About Me"),
          _buildTextField(
            controller: _aboutController,
            hint: "Share a bit about yourself...",
            icon: Icons.auto_awesome_outlined,
            primaryColor: primaryColor,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color primaryColor,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}