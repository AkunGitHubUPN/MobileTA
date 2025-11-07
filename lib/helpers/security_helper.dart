import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session.dart';

class SecurityHelper {
  SecurityHelper._privateConstructor();
  static final SecurityHelper instance = SecurityHelper._privateConstructor();

  final _storage = const FlutterSecureStorage();

  String _getPinKey(int userId) => 'pin_user_$userId';
  String _getLockEnabledKey(int userId) => 'lock_enabled_user_$userId';

  int _getCurrentUserId() {
    final userId = UserSession.instance.currentUserId;
    if (userId == null) {
      throw Exception("Tidak ada user yang aktif saat mencoba akses keamanan.");
    }
    return userId;
  }

  Future<void> setPin(String pin) async {
    final userId = _getCurrentUserId();
    await _storage.write(key: _getPinKey(userId), value: pin);
  }

  Future<String?> getPin() async {
    final userId = _getCurrentUserId();
    return await _storage.read(key: _getPinKey(userId));
  }

  Future<void> deletePin() async {
    final userId = _getCurrentUserId();
    await _storage.delete(key: _getPinKey(userId));
  }

  Future<bool> isPinSet() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setLockEnabled(bool isEnabled) async {
    final userId = _getCurrentUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getLockEnabledKey(userId), isEnabled);
    
    if (!isEnabled) {
      await deletePin();
    }
  }

  Future<bool> isLockEnabled() async {
    try {
      final userId = _getCurrentUserId();
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_getLockEnabledKey(userId)) ?? false;
    } catch (e) {
      return false;
    }
  }
}