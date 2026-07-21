import 'package:shared_preferences/shared_preferences.dart';

class OfficerAuthStore {
  static final Map<String, Map<String, String>> officers = {
    'officer1': {'id': '1234567890', 'password': 'officer123'},
    'admin': {'id': '0987654321', 'password': 'admin123'},
  };

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final username in officers.keys) {
      final saved = prefs.getString('officer_password_$username');
      if (saved != null && saved.isNotEmpty) {
        officers[username]!['password'] = saved;
      }
    }
  }

  static String? findUsername(String identifier) {
    if (officers.containsKey(identifier)) return identifier;
    for (final entry in officers.entries) {
      if (entry.value['id'] == identifier) return entry.key;
    }
    return null;
  }

  static bool verify(String identifier, String password) {
    final username = findUsername(identifier);
    if (username == null) return false;
    return officers[username]?['password'] == password;
  }

  static Future<bool> resetPassword({
    required String username,
    required String id,
    required String newPassword,
  }) async {
    final officer = officers[username];
    if (officer == null || officer['id'] != id) return false;
    officer['password'] = newPassword;
    await _savePassword(username, newPassword);
    return true;
  }

  static Future<void> setPassword(String username, String newPassword) async {
    final officer = officers[username];
    if (officer == null) return;
    officer['password'] = newPassword;
    await _savePassword(username, newPassword);
  }

  static Future<void> _savePassword(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('officer_password_$username', password);
  }
}
