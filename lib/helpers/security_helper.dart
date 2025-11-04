import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityHelper {
  final _storage = const FlutterSecureStorage();
  
  // Ini adalah key untuk menyimpan PIN di secure storage
  static const _pinKey = 'app_passkey';
  
  // Ini adalah key untuk menyimpan status (on/off) di shared preferences
  static const _lockEnabledKey = 'isAppLockEnabled';

  // --- Fungsi untuk PIN (Secure) ---

  // Menyimpan PIN baru
  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  // Mengambil PIN yang tersimpan
  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  // Menghapus PIN
  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  // Cek apakah PIN sudah pernah di-set
  Future<bool> isPinSet() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  // --- Fungsi untuk Status (Non-Secure) ---

  // Mengaktifkan atau menonaktifkan kunci aplikasi
  Future<void> setLockEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, isEnabled);
  }

  // Cek apakah kunci aplikasi sedang aktif (enabled)
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default-nya false (tidak aktif)
    return prefs.getBool(_lockEnabledKey) ?? false;
  }
}