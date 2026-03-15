import 'dart:ui';
import 'package:flowchat/util/ScreenUtil.dart';
import 'package:flutter/material.dart';

class AuthScreenNew extends StatefulWidget {
  final void Function(String) onLogin;

  const AuthScreenNew({required this.onLogin, super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreenNew> {
  final _contactController = TextEditingController();
  bool _isLoading = false;

  // Unique Theme Colors
  final Color primaryColor = const Color(0xFFFF7F50); // Coral
  final Color secondaryColor = const Color(0xFF6C63FF); // Purple-Blue

  void _login() async {
    final loggedInContact = _contactController.text.trim();
    if (loggedInContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your phone number"),
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

    try {
      widget.onLogin(loggedInContact);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // 1. Detect Tablet
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 2. Adaptive Asymmetric Gradient Header
          Container(
            height: screenHeight * (isTablet ? 0.55 : 0.48),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                  isTablet ? screenWidth * 0.15 : screenWidth * 0.25,
                ),
              ),
            ),
          ),

          // Decorative Background Circles (Scaled)
          Positioned(
            top: -screenWidth * 0.1,
            right: -screenWidth * 0.1,
            child: CircleAvatar(
              radius: isTablet ? 100 : screenWidth * 0.2,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: Center( // 3. Center content for Tablet
              child: Container(
                // 4. CONSTRAINT: Limit width on tablet for readability
                constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: isTablet ? 40 : screenHeight * 0.05),

                      // High-End App Identity (Responsive)
                      _buildLogoSection(screenWidth, screenHeight, isTablet),

                      SizedBox(height: isTablet ? 50 : screenHeight * 0.04),

                      // Floating Login Card (Responsive)
                      _buildLoginCard(screenWidth, screenHeight, isTablet),

                      SizedBox(height: isTablet ? 60 : screenHeight * 0.05),

                      // Footer Legal Info
                      _buildFooter(isTablet),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(double screenWidth, double screenHeight, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 30 : screenWidth * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: isTablet ? 70 : (screenWidth * 0.15).clamp(40, 70),
            color: Colors.white,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          "FlowChat",
          style: TextStyle(
            fontSize: isTablet ? 44 : ScreenUtil().getAdaptiveSize(context, 36),
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          "Connect with your besties",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: isTablet ? 18 : ScreenUtil().getAdaptiveSize(context, 16),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(double screenWidth, double screenHeight, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : screenWidth * 0.06),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 40 : screenWidth * 0.08),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: isTablet ? 28 : ScreenUtil().getAdaptiveSize(context, 24),
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your phone number to continue",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isTablet ? 16 : ScreenUtil().getAdaptiveSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isTablet ? 40 : screenHeight * 0.04),

            _buildPhoneInput(screenWidth, isTablet),

            SizedBox(height: isTablet ? 40 : screenHeight * 0.04),

            _buildContinueButton(screenWidth, screenHeight, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput(double screenWidth, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  PHONE NUMBER",
          style: TextStyle(
            fontSize: isTablet ? 13 : ScreenUtil().getAdaptiveSize(context, 11),
            fontWeight: FontWeight.w900,
            color: secondaryColor.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 2),
          ),
          child: TextField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: TextStyle(
              fontSize: isTablet ? 20 : ScreenUtil().getAdaptiveSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: "e.g. 98765 43210",
              hintStyle: TextStyle(
                color: Colors.grey.shade300,
                fontSize: isTablet ? 18 : ScreenUtil().getAdaptiveSize(context, 16),
              ),
              counterText: "",
              prefixIcon: Icon(
                Icons.phone_iphone_rounded,
                color: secondaryColor,
                size: isTablet ? 26 : ScreenUtil().getAdaptiveSize(context, 20),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: isTablet ? 22 : (screenWidth * 0.05).clamp(15, 25),
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(double screenWidth, double screenHeight, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 65 : null, // Fixed height for tablet button
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFFFF4D4D)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: EdgeInsets.symmetric(vertical: isTablet ? 0 : 15),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Text(
          "CONTINUE",
          style: TextStyle(
            fontSize: isTablet ? 18 : ScreenUtil().getAdaptiveSize(context, 16),
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "By continuing, you agree to our Terms of Service and Privacy Policy",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTablet ? 14 : ScreenUtil().getAdaptiveSize(context, 12),
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }
}