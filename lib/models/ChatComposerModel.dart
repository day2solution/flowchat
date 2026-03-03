// lib/models/ChatComposerModel.dart

// An enum to represent the different types of messages that can be composed.
// Using an enum is safer than using raw strings like 'image' or 'text'.
enum MessageType {
  text,
  image,
}

class ChatComposerModel {
  final MessageType type;
  final String message; // This will hold the message content or a URL/path for an image

  ChatComposerModel({
    required this.type,
    required this.message,
  });

  // Optional: A factory constructor to create a model from a map (e.g., from JSON)
  factory ChatComposerModel.fromMap(Map<String, dynamic> map) {
    return ChatComposerModel(
      // Convert the string type from the map back into a MessageType enum value.
      // It defaults to MessageType.text if the string doesn't match.
      type: MessageType.values.firstWhere(
            (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      message: map['text'] ?? '',
    );
  }

  // Optional: A method to convert the model to a map (e.g., to send as JSON)
  Map<String, dynamic> toMap() {
    return {
      // Convert the enum to a string for serialization.
      // This will save it as 'text' or 'image'.
      'type': type.name,
      'message': message,
    };
  }
}
