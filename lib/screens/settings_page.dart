import 'dart:io';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flowchat/services/user_api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  final MyAccount myAccount;
  const SettingsPage({super.key, required this.myAccount});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File? _profileImage;
  late final _nameController = TextEditingController(text: widget.myAccount.name);
  late final _contactController = TextEditingController(text: widget.myAccount.contactNo);
  late final _aboutController = TextEditingController(text: widget.myAccount.about);
  final _apiService = UserApiService();
  bool _loading = false;
  final ChatRepository _repo = ChatRepository();
  void _updateName() async {
    setState(() => _loading = true);
    try {
      // final result = await _apiService.updateUserName(
      //   UpdateNameRequest(
      //     name: _nameController.text.trim(),
      //     contactNo: widget.myAccount.contactNo,
      //   ),
      // );
      final dbAccount = MyAccount(
        contactNo: widget.myAccount.contactNo,
        name: _nameController.text.trim(),
        about: _aboutController.text.trim(),
      );
      await _repo.updateMyProfile(dbAccount,context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Profile updated successfully"),
      //     behavior: SnackBarBehavior.floating,
      //     backgroundColor: Colors.green.shade700,
      //   ),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> updateProfile({required String contactNo, File? profileImage}) async {
    final uri = Uri.parse("${Environment.hostApiUrl}/api/users/update-profile");
    var request = http.MultipartRequest("PUT", uri);
    request.fields["contactNo"] = contactNo;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath("file", profileImage.path));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      debugPrint("Profile updated successfully");
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
      updateProfile(contactNo: widget.myAccount.contactNo, profileImage: File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Profile Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- 1. Profile Picture Section ---
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade100, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : NetworkImage("${Environment.hostApiUrl}/uploads/profiles/${widget.myAccount.contactNo}.gif") as ImageProvider,
                      child: null, // Image handled by providers
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- 2. Information Fields ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildModernField(
                    label: "Phone Number",
                    controller: _contactController,
                    icon: Icons.call_rounded,
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  _buildModernField(
                    label: "Full Name",
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildModernField(
                    label: "About",
                    controller: _aboutController,
                    icon: Icons.info_outline_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- 3. Save Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _updateName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? Colors.blue : Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
