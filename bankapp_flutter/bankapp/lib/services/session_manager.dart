import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _keyLoginTime = 'login_time';
  static final _storage = FlutterSecureStorage();

  static Future<void> saveLoginTime() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _keyLoginTime, value: now);
  }

  static Future<bool> isSessionValid({
    Duration duration = const Duration(minutes: 10),
  }) async {
    final loginTimeStr = await _storage.read(key: _keyLoginTime);
    if (loginTimeStr == null) return false;

    final loginTime = DateTime.tryParse(loginTimeStr);
    if (loginTime == null) return false;

    return DateTime.now().difference(loginTime) <= duration;
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _keyLoginTime);
  }
}
