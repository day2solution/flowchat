class User {
  //final int id;
  final String name;
  final String? contactNo;
  final String? about;
  bool online;
  final String profileImage;
  String? lastMessage;
  int? timestamp;
  int? unreadCount;

  User({
   // required this.id,
    required this.name,
    this.contactNo,
    this.about,
    this.online = false,
    required this.profileImage,
    this.lastMessage,
    this.timestamp,
    this.unreadCount
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      //id: json['id'] is String ? int.parse(json['id']) : json['id'], // ✅ handles both int and string ids
      name: json['name'] ?? '',
      contactNo: json['contactNo'],
      about: json['about'],
      online: json['online'] ?? false,
      profileImage: json['profileImage'],
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'],
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      //'id': id,
      'name': name,
      'contactNo': contactNo,
      'about': about,
      'online': online,
      'profileImage': profileImage,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': unreadCount
    };
  }
}
