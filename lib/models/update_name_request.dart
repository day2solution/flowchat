class UpdateNameRequest {
  final String contactNo;
  final String name;

  UpdateNameRequest({required this.contactNo, required this.name});

  Map<String, dynamic> toJson() => {
    "contactNo": contactNo,
    "name": name,
  };
}
