import 'dart:convert';
import 'package:flowchat/config/environment.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import 'db_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IOWebSocketChannel? _channel;
  String? _userId;
  bool _isConnected = false; // ✅ Track actual connection state
  static const _uuid = Uuid();

  // ✅ Queue to hold messages sent while offline
  final List<String> _messageQueue = [];

  final List<void Function(ChatMessage)> _messageListeners = [];
  final List<void Function(String, bool)> _presenceListeners = [];
  final List<void Function(String)> _typingListeners = [];
  final List<void Function(String, String)> _msgStatusListeners = [];

  void connect(String userId) {
    disconnect();
    _userId = userId;
    _isConnected = false; // Reset state

    debugPrint('WebSocket connecting for: $userId');

    final url = '${Environment.socketUrl}/ws/chat?userId=$userId';
    debugPrint('🌐 Attempting connection to: $url');
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen((data) async {
        // ✅ Once we receive any data, we know the connection is active
        if (!_isConnected) {
          _isConnected = true;
          _flushQueue(); // Send pending messages
        }

        try {
          final map = jsonDecode(data);
          final action = map['action'];

          switch (action) {
            case 'message':
              final msg = ChatMessage(
                id: map['id'] ?? _uuid.v4(),
                receiverId: map['receiverId'],
                senderId: map['sender']['id'],
                content: map['content'],
                timestamp: DateTime.parse(map['timestamp']),
                status: map['status'] ?? 'SENT',
              );
              _sendDeliveredAck(msg.id, msg.senderId);
              await DbService().insertMessage(msg);
              for (var l in _messageListeners) l(msg);
              break;
            case 'delivered':
              final messageId = map['id'];
              await DbService().updateMessageStatus(messageId, 'DELIVERED');
              for (var l in _msgStatusListeners) l(messageId, 'DELIVERED');
              break;
            case 'read':
              final messageId = map['id'];
              await DbService().updateMessageStatus(messageId, 'READ');
              for (var l in _msgStatusListeners) l(messageId, 'READ');
              break;
            case 'presence':
              for (var l in _presenceListeners) l(map['userId'], map['online'] == true);
              break;
            case 'typing':
              for (var l in _typingListeners) l(map['senderId']);
              break;
          }
        } catch (e) {
          debugPrint('WS parse error $e');
        }
      }, onDone: () {
        debugPrint('WebSocket closed');
        _isConnected = false;
        reconnect(userId);
      }, onError: (err) {
        debugPrint('WebSocket error: $err');
        _isConnected = false;
        reconnect(userId);
      });
    } catch (e) {
      debugPrint("Connection error: $e");
      reconnect(userId);
    }
  }

  // ✅ Helper to send data safely
  void _safeSend(Map<String, dynamic> payload) {
    final data = jsonEncode(payload);

    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(data);
      } catch (e) {
        debugPrint("❌ Sink error: $e");
        _isConnected = false;
        _messageQueue.add(data);
        _attemptReconnect();
      }
    } else {
      debugPrint("⏳ Socket not ready. Adding message to queue.");
      _messageQueue.add(data);

      // If we aren't connected and not currently trying to connect, start connection
      if (!_isConnected) {
        _attemptReconnect();
      }
    }
  }

  bool _isReconnecting = false; // Prevents multiple simultaneous reconnect timers

  void _attemptReconnect() {
    if (_isReconnecting || _userId == null) return;

    _isReconnecting = true;
    debugPrint("🔄 Reconnect triggered for $_userId");

    Future.delayed(const Duration(seconds: 3), () {
      _isReconnecting = false;
      if (!_isConnected) {
        connect(_userId!);
      }
    });
  }

  // Update your existing reconnect to use the new logic
  void reconnect(String userId) {
    _userId = userId;
    _attemptReconnect();
  }

  // ✅ Send all queued messages once reconnected
  void _flushQueue() {
    debugPrint("🚀 Flushing queue: ${_messageQueue.length} messages");
    while (_messageQueue.isNotEmpty) {
      final data = _messageQueue.removeAt(0);
      _channel?.sink.add(data);
    }
  }

  void sendTextMessage(String chatId, String senderId, String content, String receiverId) {
    final id = _uuid.v4();
    final payload = {
      "action": "message",
      "id": id,
      "chatId": chatId,
      "sender": {"id": senderId, "name": "User"},
      "receiverId": receiverId,
      "content": content,
      "type": "text",
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    _safeSend(payload); // ✅ Use safeSend instead of direct sink access

    // Optimistic local update
    final msg = ChatMessage(
      id: id,
      receiverId: receiverId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      status: 'SENT',
    );
    DbService().insertMessage(msg);
    for (var l in _messageListeners) l(msg);
  }

  void _sendDeliveredAck(String messageId, String senderId) {
    _safeSend({
      'action': 'delivered',
      'id': messageId,
      'senderId': _userId,
      'receiverId': senderId,
    });
  }

  void sendReadAck(String messageId, String senderId) {
    _safeSend({
      'action': 'read',
      'id': messageId,
      'senderId': _userId,
      'receiverId': senderId,
    });
  }

  void sendTyping(String chatId) {
    _safeSend({"action": "typing", "receiverId": chatId, "senderId": _userId});
  }

  void onMessage(void Function(ChatMessage) cb) => _messageListeners.add(cb);
  void onMsgStatusAction(void Function(String, String) cb) => _msgStatusListeners.add(cb);
  void onTyping(void Function(String) cb) => _typingListeners.add(cb);
  void onUserPresence(void Function(String, bool) cb) => _presenceListeners.add(cb);

  void disconnect() {
    debugPrint("Disconnecting...");
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() => disconnect();
}