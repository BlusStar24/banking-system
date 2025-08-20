class User {
  final String phone;
  final String email;
  final String fullName;
  final String dob;
  final String idCard;
  final String hometown;
  final String gender;
  User({
    required this.phone,
    required this.email,
    required this.fullName,
    required this.dob,
    required this.idCard,
    required this.hometown,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'name': fullName,
      'dob': dob,
      'cccd': idCard,
      'hometown': hometown,
      'gender': gender,
      'status': 'pending',
      'customerId': '',
    };
  }
}
