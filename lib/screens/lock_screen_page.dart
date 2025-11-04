// Lokasi: lib/screens/lock_screen_page.dart

import 'package:flutter/material.dart';
import 'package:jejak_pena/helpers/security_helper.dart';
import 'package:jejak_pena/screens/home_page.dart';

// --- MODIFIKASI ---
// Enum untuk membedakan mode halaman
enum LockScreenMode { unlock, setPin, confirmPin }

// Enum untuk membedakan tujuan halaman ini dibuka
enum LockScreenPurpose { unlockApp, setupPin, changePin }

class LockScreenPage extends StatefulWidget {
  // --- MODIFIKASI ---
  // Kita tambahkan 'purpose' agar halaman ini tahu tujuannya
  final LockScreenPurpose purpose;

  const LockScreenPage({
    super.key,
    this.purpose = LockScreenPurpose.unlockApp, // Default-nya adalah buka kunci
  });

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final _pinController = TextEditingController();
  final _securityHelper = SecurityHelper();

  String _message = 'Masukkan Passkey Anda';
  String _tempPin = '';
  LockScreenMode _mode = LockScreenMode.unlock;

  @override
  void initState() {
    super.initState();
    _determineInitialMode();
  }

  // --- MODIFIKASI ---
  // Cek mode berdasarkan 'purpose'
  Future<void> _determineInitialMode() async {
    final isPinSet = await _securityHelper.isPinSet();

    setState(() {
      switch (widget.purpose) {
        case LockScreenPurpose.unlockApp:
          _mode = LockScreenMode.unlock;
          _message = 'Masukkan Passkey Anda';
          break;
        case LockScreenPurpose.setupPin:
          _mode = LockScreenMode.setPin;
          _message = 'Buat Passkey Baru (4 digit)';
          break;
        case LockScreenPurpose.changePin:
          if (isPinSet) {
            _mode = LockScreenMode.unlock;
            _message = 'Masukkan Passkey LAMA Anda';
          } else {
            // Jika tidak ada PIN, ganti jadi 'setupPin'
            _mode = LockScreenMode.setPin;
            _message = 'Buat Passkey Baru (4 digit)';
          }
          break;
      }
    });
  }

  // Dipanggil saat tombol numpad ditekan
  void _onNumpadTapped(String value) {
    if (_pinController.text.length >= 4) return;

    setState(() {
      _pinController.text += value;
    });

    // Jika 4 digit sudah dimasukkan, proses PIN
    if (_pinController.text.length == 4) {
      _processPin();
    }
  }

  // Dipanggil saat tombol backspace ditekan
  void _onBackspace() {
    if (_pinController.text.isEmpty) return;
    setState(() {
      _pinController.text =
          _pinController.text.substring(0, _pinController.text.length - 1);
    });
  }

  // --- MODIFIKASI ---
  // Logika utama untuk memproses PIN, sekarang lebih kompleks
  Future<void> _processPin() async {
    final enteredPin = _pinController.text;
    await Future.delayed(const Duration(milliseconds: 200));

    switch (_mode) {
      // --- KASUS: BUKA KUNCI / MASUKKAN PIN LAMA ---
      case LockScreenMode.unlock:
        final correctPin = await _securityHelper.getPin();
        if (enteredPin == correctPin) {
          // --- PIN LAMA BENAR ---
          if (widget.purpose == LockScreenPurpose.unlockApp) {
            // TUJUAN: Buka App -> Arahkan ke Home
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } else if (widget.purpose == LockScreenPurpose.changePin) {
            // TUJUAN: Ganti Pin -> Lanjut ke set PIN baru
            setState(() {
              _mode = LockScreenMode.setPin;
              _message = 'Masukkan Passkey BARU Anda';
              _pinController.clear();
            });
          }
        } else {
          // SALAH: Tampilkan error dan reset
          _showError('Passkey salah. Coba lagi.');
        }
        break;

      // --- KASUS: BUAT PIN BARU ---
      case LockScreenMode.setPin:
        _tempPin = enteredPin;
        setState(() {
          _mode = LockScreenMode.confirmPin;
          _message = 'Konfirmasi Passkey Baru Anda';
          _pinController.clear();
        });
        break;

      // --- KASUS: KONFIRMASI PIN ---
      case LockScreenMode.confirmPin:
        if (enteredPin == _tempPin) {
          // --- PIN BARU COCOK ---
          await _securityHelper.setPin(enteredPin);
          
          if (widget.purpose == LockScreenPurpose.setupPin) {
            // Jika ini setup awal, aktifkan lock-nya
            await _securityHelper.setLockEnabled(true);
          }
          _showSuccessAndExit();

        } else {
          // SALAH: Ulangi dari awal (tergantung tujuan)
          setState(() {
            _mode = LockScreenMode.setPin;
             _message = (widget.purpose == LockScreenPurpose.changePin)
                ? 'Passkey tidak cocok. Masukkan Passkey BARU lagi.'
                : 'Passkey tidak cocok. Silakan buat ulang.';
          });
          _showError(_message);
        }
        break;
    }
  }

  void _showError(String message) {
    setState(() {
      _message = message;
      _pinController.clear();
    });
  }

  void _showSuccessAndExit() {
    setState(() {
      _message = 'Passkey Disimpan!';
      _pinController.clear();
    });
    // Kembali ke halaman Settings
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Kirim 'true' untuk update settings page
        Navigator.pop(context, true); 
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kunci Aplikasi'),
        backgroundColor: const Color(0xFFFF6B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        // Jangan tampilkan tombol back jika sedang buka kunci app
        automaticallyImplyLeading: widget.purpose != LockScreenPurpose.unlockApp,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFFFF6B4A)),
            const SizedBox(height: 32),
            Text(
              _message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B4A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildPinDisplay(),
            const Spacer(),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }
  Widget _buildPinDisplay() {
    int length = _pinController.text.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < length 
              ? const Color(0xFFFF6B4A) 
              : Colors.grey.shade300,
            boxShadow: index < length 
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B4A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
          ),
        );
      }),
    );
  }
  Widget _buildNumpad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        String text;
        VoidCallback? onTap;

        if (index < 9) { // Tombol 1-9
          text = (index + 1).toString();
          onTap = () => _onNumpadTapped(text);
          return _buildNumpadButton(text, onTap);
        } else if (index == 9) { // Tombol kosong
          return const SizedBox();
        } else if (index == 10) { // Tombol 0
          text = '0';
          onTap = () => _onNumpadTapped(text);
          return _buildNumpadButton(text, onTap);
        } else { // Tombol backspace
          return _buildBackspaceButton();
        }
      },
    );
  }

  Widget _buildNumpadButton(String text, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade100,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B4A),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade100,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 32,
              color: Color(0xFFFF6B4A),
            ),
          ),
        ),
      ),
    );
  }
}