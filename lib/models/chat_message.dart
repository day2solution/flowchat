class ChatMessage {
  final String id;
  final String receiverId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  String status; // SENT, DELIVERED, READ

  ChatMessage({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.status = 'SENT',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'receiverId': receiverId,
    'senderId': senderId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id: m['id'],
    receiverId: m['receiverId'],
    senderId: m['senderId'],
    content: m['content'],
    timestamp: DateTime.parse(m['timestamp']),
    status: m['status'],
  );
}
