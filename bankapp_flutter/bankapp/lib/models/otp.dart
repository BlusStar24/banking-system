class Otp {
  final String code;

  Otp({required this.code});

  Map<String, dynamic> toJson() => {'code': code};
}