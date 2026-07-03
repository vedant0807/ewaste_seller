import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String _keyUserId = 'userId';
  static const String _keyAccessToken = 'accessToken';
  static const String _keyRefreshToken = 'refreshToken';
  static const String _keyName = 'name';
  static const String _keyPhoneNumber = 'phoneNumber';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'role';

  Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final seller = data['seller'] as Map<String, dynamic>?;
    if (seller != null) {
      await prefs.setString(_keyUserId, seller['id']?.toString() ?? '');
      await prefs.setString(_keyName, seller['username'] ?? '');
      await prefs.setString(_keyPhoneNumber, seller['phoneNumber'] ?? '');
      await prefs.setString(_keyEmail, seller['email'] ?? '');
      await prefs.setString(_keyRole, seller['role'] ?? '');
    }

    if (data['accessToken'] != null) {
      await prefs.setString(_keyAccessToken, data['accessToken']);
    }
    if (data['refreshToken'] != null) {
      await prefs.setString(_keyRefreshToken, data['refreshToken']);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumber);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
