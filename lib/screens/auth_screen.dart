import 'package:flowchat/config/Logger.dart';
import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';

class AuthScreen extends StatefulWidget {
  final void Function(String, String) onLogin;
  const AuthScreen({required this.onLogin, super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameCtrl = TextEditingController();
  final _contactNoCtrl = TextEditingController();
  // final _uuid = const Uuid();

  void _login() {
    Logger.log("auth_screen","here 2");
    final loggesInUsername = _nameCtrl.text.trim();
    final loggedInContact = _contactNoCtrl.text.trim();
    if (loggesInUsername.isEmpty) return;

    if (loggedInContact.isEmpty) return;
    // For demo, we use uuid as userId. In real app, call REST login and get userId/JWT.
    // final userId = _uuid.v4();
    widget.onLogin(loggesInUsername,loggedInContact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login (demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 12),
            TextField(controller: _contactNoCtrl, decoration: const InputDecoration(labelText: 'Contact Number')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login (demo)')),
          ],
        ),
      ),
    );
  }
}
