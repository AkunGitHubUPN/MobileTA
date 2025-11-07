import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession._privateConstructor();
  static final UserSession instance = UserSession._privateConstructor();
  static const String _kLoggedInUserId = 'logged_in_user_id';

  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  bool get isLoggedIn => _currentUserId != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt(_kLoggedInUserId);
    if (_currentUserId != null) {
      print("[SESSION] User ID $_currentUserId ditemukan. Auto-login berhasil.");
    } else {
      print("[SESSION] Tidak ada sesi aktif.");
    }
  }

  Future<void> saveSession(int userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLoggedInUserId, userId);
    print("[SESSION] Sesi disimpan untuk User ID: $userId");
  }

  Future<void> clearSession() async {
    print("[SESSION] Menghapus sesi untuk User ID: $_currentUserId");
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedInUserId);
  }
}