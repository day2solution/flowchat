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

  void _login() async {
    final loggedInContact = _contactController.text.trim();
    if (loggedInContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your phone number"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Warm Gradient Background Header
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // 2. Friendly Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded, // More "Social/Magic" feel
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "FlowChat",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    "Connect with your besties",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 50),

                  // 3. Login Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter your phone number to get started",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                          const SizedBox(height: 32),

                          // Phone Input
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _contactController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "Phone Number",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                prefixIcon: Icon(Icons.phone_android_rounded, color: primaryColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: primaryColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                "Continue",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. Footer Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "By continuing, you agree to our Terms of Service and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.5,
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
}