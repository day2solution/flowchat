class RecentChat {
  final String contactNo; // primary key instead of userId
  final String name;
  final String lastMessage;
  final int timestamp; // epoch millis
  final String? profileImage;
  bool? online;

  RecentChat({
    required this.contactNo,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    this.profileImage,
    this.online,
  });

  Map<String, dynamic> toMap() {
    return {
      'contactNo': contactNo,
      'name': name,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'profileImage': profileImage,
      'online': online,
    };
  }

  factory RecentChat.fromMap(Map<String, dynamic> map) {
    return RecentChat(
      contactNo: map['contactNo'],
      name: map['name'],
      lastMessage: map['lastMessage'],
      timestamp: map['timestamp'],
      profileImage: map['profileImage'],
      online: map['online'],
    );
  }
}
