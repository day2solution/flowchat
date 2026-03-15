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

  // Focus nodes for better keyboard navigation
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _aboutFocus = FocusNode();

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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _nameFocus.dispose();
    _aboutFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(isTablet, screenWidth, screenHeight),

            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 550 : double.infinity,
                ),
                padding: EdgeInsets.fromLTRB(24, 0, 24, screenHeight / 20),
                child: Column(
                  children: [
                    SizedBox(height: isTablet ? 40 : screenHeight / 20),

                    _buildUniqueTextField(
                      label: "FULL NAME",
                      controller: _nameController,
                      focusNode: _nameFocus,
                      nextFocus: _aboutFocus,
                      icon: Icons.person_rounded,
                      color: primaryColor,
                      autofillHints: [AutofillHints.name],
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
                      focusNode: _aboutFocus,
                      icon: Icons.bubble_chart_rounded,
                      color: Colors.orange,
                      maxLines: 3,
                      maxLength: 120, // Limit bio length
                    ),

                    SizedBox(height: (screenHeight / 15).clamp(40.0, 80.0)),

                    _buildSubmitButton(isTablet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, double screenWidth, double screenHeight) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: isTablet ? 300 : screenHeight / 3,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(isTablet ? 120 : 80),
            ),
          ),
        ),
        // Decorative background circle
        Positioned(
          top: -screenWidth / 8,
          right: -screenWidth / 8,
          child: CircleAvatar(
            radius: isTablet ? 150 : screenWidth / 4,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                widget.isNewProfile ? "Welcome!" : "Profile Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 32 : ScreenUtil().getAdaptiveSize(context, 26),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: isTablet ? 40 : screenHeight / 25),
              _buildAvatarPicker(isTablet, screenWidth),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPicker(bool isTablet, double screenWidth) {
    final double avatarRadius = isTablet ? 90 : (screenWidth / 6).clamp(50.0, 75.0);

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Hero(
              tag: 'profile_pic',
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : NetworkImage(
                  "${Environment.hostApiUrl}/uploads/profiles/${widget.myAccount.contactNo}.gif",
                ) as ImageProvider,
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              height: avatarRadius / 1.5,
              width: avatarRadius / 1.5,
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                Icons.camera_enhance_rounded,
                color: Colors.white,
                size: avatarRadius / 3.5,
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
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          autofillHints: autofillHints,
          textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onSubmitted: (_) {
            if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
          },
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 22),
            counterText: "", // Hide default counter to use custom or keep clean
            suffix: maxLength != null
                ? ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, child) {
                return Text(
                  '${value.text.length}/$maxLength',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                );
              },
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade100, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: color.withOpacity(0.5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color.withOpacity(0.4), size: 22),
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade100, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isTablet ? 65 : 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, const Color(0xFFFF4D4D)]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Text(
              widget.isNewProfile ? "GET STARTED" : "SAVE CHANGES",
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512, // Optimization: resize before upload
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your full name"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

      // If there's an image, you would typically call an upload method here
      // await _repo.uploadProfileImage(_imageFile, widget.myAccount.contactNo);

      if (mounted) {
        if (widget.isNewProfile) {
          WebSocketService().connect(dbAccount.contactNo);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ChatListScreen(myAccount: fetchedAccount ?? dbAccount)),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong. Please try again.")),
        );
      }
    }
  }
}