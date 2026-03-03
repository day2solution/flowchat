class MyAccount {
  final String contactNo;
  final String? name;
  final String? about;

  MyAccount({
    required this.contactNo,
    required this.name,
    required this.about,
  });

  // Convert object to Map (for DB / JSON)
  Map<String, dynamic> toMap() {
    return {
      'contactNo': contactNo,
      'name': name,
      'about': about,
    };
  }

  // Create object from Map (for DB / JSON)
  factory MyAccount.fromMap(Map<String, dynamic> map) {
    return MyAccount(
      contactNo: map['contactNo'],
      name: map['name'],
      about: map['about'],
    );
  }

  // Optional: convert to JSON
  String toJson() => toMap().toString();

  // Optional: create from JSON
  factory MyAccount.fromJson(Map<String, dynamic> json) {
    return MyAccount(
      contactNo: json['contactNo'],
      name: json['name'],
      about: json['about'],
    );
  }
}
