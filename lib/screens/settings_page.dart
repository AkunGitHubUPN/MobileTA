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
    final isLockEnabled = await _securityHelper.isLockEnabled();
    final isPinSet = await _securityHelper.isPinSet();

    setState(() {
      _isLockEnabled = isLockEnabled;
      _isPinSet = isPinSet;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B4A),
      ),
    );
  }

  Future<void> _onLockEnabledChanged(bool value) async {
    if (value == true) {
      if (!_isPinSet) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LockScreenPage(purpose: LockScreenPurpose.setupPin),
          ),
        );
        if (result == true) {
          _loadSettings();
          _showSnackBar('Kunci aplikasi diaktifkan');
        }
      } else {
        await _securityHelper.setLockEnabled(true);
        setState(() {
          _isLockEnabled = true;
        });
        _showSnackBar('Kunci aplikasi diaktifkan');
      }
    } else {
      await _securityHelper.setLockEnabled(false);
      setState(() {
        _isLockEnabled = false;
      });
      _showSnackBar('Kunci aplikasi dinonaktifkan');
    }
  }

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

  Future<void> _onNotificationEnabledChanged(bool value) async {
    setState(() {
      _isNotificationEnabled = value;
    });

    if (value) {
      _showSnackBar('Notifikasi telah diaktifkan');
      await _notificationHelper.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Notifikasi Aktif! 🔔',
        body: 'Notifikasi aplikasi telah dinyalakan.',
      );
    } else {
      _showSnackBar('Notifikasi telah dimatikan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFFF6B4A),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Card Keamanan
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Keamanan',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B4A),
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Aktifkan Kunci Aplikasi'),
                        value: _isLockEnabled,
                        activeColor: const Color(0xFFFF6B4A),
                        onChanged: _onLockEnabledChanged,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Ubah Passkey'),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF6B4A)),
                        enabled: _isPinSet,
                        onTap: _onChangePasskey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card Notifikasi
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Notifikasi',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B4A),
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Aktifkan Notifikasi'),
                        value: _isNotificationEnabled,
                        activeColor: const Color(0xFFFF6B4A),
                        onChanged: _onNotificationEnabledChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card Tentang
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Tentang',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B4A),
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Tentang Aplikasi'),
                        subtitle: const Text('Informasi aplikasi dan feedback'),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF6B4A)),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}