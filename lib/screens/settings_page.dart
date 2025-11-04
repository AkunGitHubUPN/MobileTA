// Lokasi: lib/screens/settings_page.dart

import 'package:flutter/material.dart';
import '../helpers/security_helper.dart';
import '../helpers/notification_helper.dart';
import 'lock_screen_page.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Pengaturan Keamanan
  final _securityHelper = SecurityHelper();
  final _notificationHelper = NotificationHelper.instance;
  bool _isLockEnabled = false;
  bool _isPinSet = false;
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Muat data keamanan
    final isLockEnabled = await _securityHelper.isLockEnabled();
    final isPinSet = await _securityHelper.isPinSet();

    setState(() {
      _isLockEnabled = isLockEnabled;
      _isPinSet = isPinSet;
    });
  }
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Fungsi untuk menangani 'Aktifkan Kunci Aplikasi'
  Future<void> _onLockEnabledChanged(bool value) async {
    if (value == true) {
      // Saat MENYALAKAN lock
      if (!_isPinSet) {
        // 1. Jika PIN BELUM ADA, navigasi ke setup PIN
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LockScreenPage(purpose: LockScreenPurpose.setupPin),
          ),
        );
        // Jika setup berhasil (user tidak menekan 'back')
        if (result == true) {
          _loadSettings(); // Muat ulang semua settings
          _showSnackBar('Kunci aplikasi diaktifkan');
        }
      } else {
        // 2. Jika PIN SUDAH ADA, langsung aktifkan
        await _securityHelper.setLockEnabled(true);
        setState(() {
          _isLockEnabled = true;
        });
        _showSnackBar('Kunci aplikasi diaktifkan');
      }
    } else {
      // Saat MEMATIKAN lock
      await _securityHelper.setLockEnabled(false);
      setState(() {
        _isLockEnabled = false;
      });
      _showSnackBar('Kunci aplikasi dinonaktifkan');
    }
  }
  // Fungsi untuk 'Ubah Passkey'
  Future<void> _onChangePasskey() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LockScreenPage(purpose: LockScreenPurpose.changePin),
      ),
    );

    if (result == true) {
      _showSnackBar('Passkey berhasil diubah');
    }
  }

  // Fungsi untuk menangani 'Aktifkan/Matikan Notifikasi'
  Future<void> _onNotificationEnabledChanged(bool value) async {
    setState(() {
      _isNotificationEnabled = value;
    });

    if (value) {
      // Notifikasi DIAKTIFKAN
      _showSnackBar('Notifikasi telah diaktifkan');
      // Tampilkan notifikasi konfirmasi
      await _notificationHelper.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Notifikasi Aktif! 🔔',
        body: 'Notifikasi aplikasi telah dinyalakan.',
      );
    } else {
      // Notifikasi DIMATIKAN
      _showSnackBar('Notifikasi telah dimatikan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // BAGIAN KEAMANAN
          Text(
            'Keamanan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          SwitchListTile(
            title: const Text('Aktifkan Kunci Aplikasi'),
            value: _isLockEnabled,
            onChanged: _onLockEnabledChanged,
          ),          ListTile(
            title: const Text('Ubah Passkey'),
            trailing: const Icon(Icons.key),
            enabled: _isPinSet,
            onTap: _onChangePasskey,
          ),
          const SizedBox(height: 24),

          // BAGIAN NOTIFIKASI
          Text(
            'Notifikasi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          SwitchListTile(
            title: const Text('Aktifkan Notifikasi'),
            value: _isNotificationEnabled,
            onChanged: _onNotificationEnabledChanged,
          ),
          const SizedBox(height: 24),

          // BAGIAN TENTANG
          Text(
            'Tentang',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            title: const Text('Tentang Aplikasi'),
            subtitle: const Text('Informasi aplikasi dan feedback'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}