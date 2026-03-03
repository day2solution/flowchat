import 'dart:convert';

class MessageModel {
  final UserMsg sender;
  final UserMsg recipient;
  final String content;
  final String room;
  final String type;
  final bool image;
  final String? imageName;
  final String? fileType;

  MessageModel({
    required this.sender,
    required this.recipient,
    required this.content,
    required this.room,
    required this.type,
    required this.image,
    this.imageName,
    this.fileType
  });

  // Convert from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {

    return MessageModel(
      sender: UserMsg.fromJson(json['sender']),
      recipient:  UserMsg.fromJson(json['recipient']),
      content: json['content'] ?? '',
        room:json['room']??'',
        type:json['type']??'',
        image:json['image']??false,
      imageName:json['imageName'],
      fileType:json['fileType'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sender': sender.toJson(),
      'recipient': recipient.toJson(),
      'content': content,
      'room':room,
      'type':type,
      'image':image,
      'imageName':imageName,
      'fileType':fileType

    };
  }
}

class UserMsg {

  final int userId;
  final String name;
  final int contactNo;

  UserMsg({
    required this.userId,
    required this.name,
    required this.contactNo,
  });

  // Convert from JSON
  factory UserMsg.fromJson(Map<String, dynamic> json) {
    return UserMsg(

      userId: json['userId'],
      name: json['name'] ?? '',
      contactNo: json['contactNo'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'contactNo': contactNo,
    };
  }
}
