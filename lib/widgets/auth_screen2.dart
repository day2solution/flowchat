import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AuthScreen2 extends StatefulWidget {
  final void Function(String) onLogin;
  const AuthScreen2({required this.onLogin, super.key});

  @override
  State<AuthScreen2> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen2> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _uuid = const Uuid();

  void _login() {
    debugPrint("here 1");
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    // For demo, we use uuid as userId. In real app, call REST login and get userId/JWT.
    final userId = _uuid.v4();
    widget.onLogin(userId);
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
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email (optional)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login (demo)')),
          ],
        ),
      ),
    );
  }
}
