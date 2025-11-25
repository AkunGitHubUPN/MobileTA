import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/notification_helper.dart';
import '../helpers/user_session.dart';
import '../helpers/security_helper.dart';
import 'lock_screen_page.dart';
import 'about_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _notificationHelper = NotificationHelper.instance;
  bool _isNotificationEnabled = true;
  final _securityHelper = SecurityHelper.instance;
  bool _isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _onLockEnabledChanged(bool value) async {
    if (value) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LockScreenPage(purpose: LockScreenPurpose.setupPin),
        ),
      );

      if (result == true) {
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

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF6B4A)),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;

    final isLockEnabled = await _securityHelper.isLockEnabled();
    setState(() {
      _isLockEnabled = isLockEnabled;
      _isNotificationEnabled = isNotificationEnabled;
    });
  }

  Future<void> _onNotificationEnabledChanged(bool value) async {
    setState(() {
      _isNotificationEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);

    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi diaktifkan'),
          backgroundColor: Color(0xFFFF6B4A),
        ),
      );
      await _notificationHelper.showInstantNotification(
        id: 999,
        title: 'Notifikasi Aktif! 🔔',
        body: 'JejakPena akan mengingatkan momen berharga Anda.',
      );
    }
  }

  void _doLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await UserSession.instance.clearSession();

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFF6B4A),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSettingsCard(
                  title: 'Keamanan',
                  children: [
                    SwitchListTile(
                      title: const Text('Kunci Aplikasi'),
                      subtitle: const Text(
                        'Minta passkey saat aplikasi dibuka',
                      ),
                      value: _isLockEnabled,
                      activeColor: const Color(0xFFFF6B4A),
                      onChanged: _onLockEnabledChanged,
                    ),
                    if (_isLockEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.lock_reset,
                          color: Colors.grey,
                        ),
                        title: const Text('Ubah Passkey'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LockScreenPage(
                                purpose: LockScreenPurpose.changePin,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                  
                ),
                const SizedBox(height: 16),

                _buildSettingsCard(
                  title: 'Umum',
                  children: [
                    SwitchListTile(
                      title: const Text('Notifikasi Aplikasi'),
                      subtitle: const Text(
                        'Aktifkan notifikasi di perangkat ini',
                      ),
                      value: _isNotificationEnabled,
                      activeColor: const Color(0xFFFF6B4A),
                      onChanged: _onNotificationEnabledChanged,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSettingsCard(
                  title: 'Lainnya',
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFF6B4A),
                      ),
                      title: const Text('Tentang Aplikasi'),
                      trailing: const Icon(Icons.chevron_right),
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

                const SizedBox(height: 16),

                _buildSettingsCard(
                  title: 'Akun',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Keluar Akun'),
                      onTap: _doLogout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B4A),
                fontSize: 16,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
