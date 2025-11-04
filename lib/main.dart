// Lokasi: lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'helpers/security_helper.dart';
import 'screens/lock_screen_page.dart';
import 'helpers/notification_helper.dart';
import 'package:intl/date_symbol_data_local.dart';
// helpers/notification_helper.dart (Duplikat import, dihapus)

Future<void> main() async {
  // Pastikan binding Flutter siap sebelum menjalankan logic async
  WidgetsFlutterBinding.ensureInitialized(); 

  // --- INISIALISASI LOCALE ---
  // Inisialisasi locale untuk formatting tanggal
  await initializeDateFormatting('id_ID', null);

  // --- PERBAIKAN ---
  // Inisialisasi notifikasi lokal (HANYA SATU KALI DI SINI)
  print("[MAIN] Menginisialisasi NotificationHelper...");
  await NotificationHelper.instance.init();
  print("[MAIN] Inisialisasi Selesai.");
  // --- AKHIR PERBAIKAN ---

  // Cek status kunci aplikasi
  final securityHelper = SecurityHelper();
  final isLockEnabled = await securityHelper.isLockEnabled();

  // Tentukan halaman mana yang akan dibuka pertama kali
  final Widget initialPage;
  if (isLockEnabled) {
    initialPage = const LockScreenPage(purpose: LockScreenPurpose.unlockApp);
  } else {
    initialPage = const HomePage();
  }

  // Kirim halaman awal ke MyApp
  runApp(MyApp(initialPage: initialPage));

  // --- BLOK YANG BERMASALAH SUDAH DIHAPUS ---
}

class MyApp extends StatelessWidget {
  // Terima halaman awal dari main()
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JejakPena',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: initialPage,
    );
  }
}