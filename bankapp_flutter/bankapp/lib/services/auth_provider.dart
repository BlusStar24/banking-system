import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userName;
  final _storage = FlutterSecureStorage();

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;

  Future<void> login(String token, String userName) async {
    await _storage.write(key: 'auth_token', value: token);
    _isLoggedIn = true;
    _userName = userName;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _isLoggedIn = false;
    _userName = null;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _isLoggedIn = true;
      // TODO: Gọi API getUserProfile để lấy userName
      _userName = 'User';
      notifyListeners();
    }
  }
}