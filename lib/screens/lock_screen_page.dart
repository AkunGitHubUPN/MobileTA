import 'package:flutter/material.dart';
import '../helpers/security_helper.dart';
import '../helpers/database_helper.dart';
import '../helpers/user_session.dart';
import 'home_page.dart';

enum LockScreenMode { unlock, setPin, confirmPin }
enum LockScreenPurpose { unlockApp, setupPin, changePin }

class LockScreenPage extends StatefulWidget {
  final LockScreenPurpose purpose;

  const LockScreenPage({
    super.key,
    this.purpose = LockScreenPurpose.unlockApp,
  });
  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final _pinController = TextEditingController();
  final _securityHelper = SecurityHelper.instance;

  String _message = 'Masukkan Passkey';
  String _tempPin = '';
  LockScreenMode _mode = LockScreenMode.unlock;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determineInitialMode();
  }

  void _determineInitialMode() {
    setState(() {
      switch (widget.purpose) {
        case LockScreenPurpose.unlockApp:
          _mode = LockScreenMode.unlock;
          _message = 'Masukkan Passkey Anda';
          break;
        case LockScreenPurpose.setupPin:
        case LockScreenPurpose.changePin: 
          _mode = LockScreenMode.setPin;
          _message = 'Buat Passkey Baru';
          break;
      }
    });
  }

  void _onNumpadTapped(String value) {
    if (_pinController.text.length >= 4) return;
    setState(() => _pinController.text += value);
    if (_pinController.text.length == 4) _processPin();
  }

  void _onBackspace() {
    if (_pinController.text.isEmpty) return;
    setState(() => _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1));
  }

  Future<void> _processPin() async {
    if (_isLoading) return;
    final enteredPin = _pinController.text;
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      switch (_mode) {
        case LockScreenMode.unlock:
          final correctPin = await _securityHelper.getPin();
          if (enteredPin == correctPin) {
            if (mounted) {
               Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => const HomePage())
              );
            }
          } else {
            _showError('Passkey salah');
          }
          break;

        case LockScreenMode.setPin:
          setState(() {
            _tempPin = enteredPin;
            _mode = LockScreenMode.confirmPin;
            _message = 'Konfirmasi Passkey Baru';
            _pinController.clear();
            _isLoading = false;
          });
          break;

        case LockScreenMode.confirmPin:
          if (enteredPin == _tempPin) {
            await _securityHelper.setPin(enteredPin);
            
            if (widget.purpose == LockScreenPurpose.setupPin) {
              await _securityHelper.setLockEnabled(true);
            }
            
            if (mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Passkey berhasil disimpan'), 
                  backgroundColor: Color(0xFFFF6B4A)
                ),
              );
            }
          } else {
            setState(() {
              _mode = LockScreenMode.setPin;
              _message = 'Passkey tidak cocok. Ulangi baru.';
              _pinController.clear();
              _isLoading = false;
            });
          }
          break;
      }
    } catch (e) {
      _showError("Terjadi kesalahan: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _pinController.clear();
      _isLoading = false;
    });
  }

  void _showForgotPinDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Lupa Passkey?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masuk dengan akun Anda untuk mereset passkey.'),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                ),
                if (isVerifying)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(color: Color(0xFFFF6B4A)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B4A), foregroundColor: Colors.white),
                onPressed: isVerifying ? null : () async {
                  setStateDialog(() => isVerifying = true);
                  
                  final user = await DatabaseHelper.instance.loginUser(
                    usernameController.text.trim(),
                    passwordController.text,
                  );

                  final currentUserId = UserSession.instance.currentUserId;
                  
                  if (user != null && user[DatabaseHelper.columnUserId] == currentUserId) {
                    await _securityHelper.setLockEnabled(false);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passkey berhasil direset. Silakan atur ulang di Pengaturan.')),
                      );
                    }
                  } else {
                     setStateDialog(() => isVerifying = false);
                     if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verifikasi gagal. Kredensial salah.'), backgroundColor: Colors.red),
                        );
                     }
                  }
                },
                child: const Text('Verifikasi'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.purpose == LockScreenPurpose.unlockApp
          ? null
          : AppBar(
              title: const Text('Kunci Aplikasi'),
              backgroundColor: const Color(0xFFFF6B4A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.lock_outline, size: 60, color: Color(0xFFFF6B4A)),
              const SizedBox(height: 24),
              Text(
                _message,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pinController.text.length ? const Color(0xFFFF6B4A) : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const Spacer(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1.5, mainAxisSpacing: 16, crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return widget.purpose == LockScreenPurpose.unlockApp 
                      ? Center(
                          child: TextButton(
                            onPressed: _showForgotPinDialog,
                            child: const Text('Lupa?', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ),
                        )
                      : const SizedBox();
                  }
                  if (index == 11) {
                    return IconButton(
                      onPressed: _onBackspace,
                      icon: const Icon(Icons.backspace_outlined, color: Color(0xFFFF6B4A)),
                    );
                  }
                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onNumpadTapped(number),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(number, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B4A))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}