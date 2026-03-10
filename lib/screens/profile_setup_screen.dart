import 'dart:io';
import 'package:flowchat/util/ScreenUtil.dart';
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

  // Responsive values
  late double screenWidth;
  late double screenHeight;

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
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, screenHeight / 20),
              child: Column(
                children: [
                  SizedBox(height: screenHeight / 20),
                  _buildUniqueTextField(
                    label: "FULL NAME",
                    controller: _nameController,
                    icon: Icons.person_rounded,
                    color: primaryColor,
                  ),
                  SizedBox(height: screenHeight / 40),
                  _buildUniqueContactNumField(
                    label: "PHONE NUMBER",
                    controller: _phoneController,
                    icon: Icons.phone_iphone_rounded,

                    color: secondaryColor,
                    enabled: false,
                  ),
                  SizedBox(height: screenHeight / 40),
                  _buildUniqueTextField(
                    label: "ABOUT ME",
                    controller: _aboutController,
                    icon: Icons.bubble_chart_rounded,
                    color: Colors.orange,
                    maxLines: 3,
                  ),
                  SizedBox(height: (screenHeight / 15).clamp(30.0, 60.0)),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Artistic Background Shape
        Container(
          height: screenHeight / 3,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(80),
            ),
          ),
        ),
        // Decorative Circles (Responsive Radius)
        Positioned(
          top: -screenWidth / 8,
          right: -screenWidth / 8,
          child: CircleAvatar(
            radius: screenWidth / 4,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight / 120),
              Text(
                widget.isNewProfile ? "Welcome!" : "Profile Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenUtil().getAdaptiveSize(context, 26),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: screenHeight / 25),
              _buildAvatarPicker(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPicker() {
    final double avatarRadius = (screenWidth / 6).clamp(50.0, 75.0);

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
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : NetworkImage(
                          "${Environment.hostApiUrl}/uploads/profiles/${widget.myAccount.contactNo}.gif",
                        )
                        as ImageProvider,
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              height: avatarRadius / 1.5,
              width: avatarRadius / 1.5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: avatarRadius / 3,
              ),
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
            fontSize: ScreenUtil().getAdaptiveSize(context, 12),
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: 0.8),
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
                color: color.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ScreenUtil().getAdaptiveSize(context, 16),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: color,size: ScreenUtil().getAdaptiveSize(context, 20),),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(screenWidth / 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUniqueContactNumField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(
            fontSize: ScreenUtil().getAdaptiveSize(context, 12),
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            // Slightly different color for disabled
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 2),
          ),
          child: TextField(
            controller: controller,
            maxLength: 10,
            enabled: enabled,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ScreenUtil().getAdaptiveSize(context, 16),
              color: Colors.grey,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: color.withValues(alpha: 0.5),size: ScreenUtil().getAdaptiveSize(context, 20),),
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(screenWidth / 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      // height: (screenHeight / 12).clamp(55.0, 70.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFFFF4D4D)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.isNewProfile ? "GET STARTED" : "SAVE CHANGES",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenUtil().getAdaptiveSize(context, 18),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  // Logic remains identical to your original code
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submit() async {
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
        if (widget.isNewProfile) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChatListScreen(myAccount: fetchedAccount ?? dbAccount),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
