class User {
  final String name;
  final String? contactNo;
  final String? about;
  bool online;
  final String profileImage;
  String? lastMessage;
  int? timestamp;
  int? unreadCount;

  User({
    required this.name,
    this.contactNo,
    this.about,
    this.online = false,
    required this.profileImage,
    this.lastMessage,
    this.timestamp,
    this.unreadCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      contactNo: json['contactNo'],
      about: json['about'],
      // ✅ Handle both API (bool) and SQLite (int 0/1)
      online: json['online'] is int
          ? json['online'] == 1
          : (json['online'] ?? false),
      profileImage: json['profileImage'] ?? '',
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'],
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contactNo': contactNo,
      'about': about,
      // ✅ Convert bool to int (1/0) for SQLite storage compatibility
      'online': online ? 1 : 0,
      'profileImage': profileImage,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': unreadCount,
    };
  }
}