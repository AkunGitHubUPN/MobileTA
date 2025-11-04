// Lokasi: lib/helpers/notification_helper.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  // Buat jadi Singleton
  NotificationHelper._privateConstructor();
  static final NotificationHelper instance = NotificationHelper._privateConstructor();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Fungsi Inisialisasi Utama
  Future<void> init() async {
    // --- Konfigurasi Pengaturan Notifikasi ---
    // Pengaturan untuk Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher', // Gunakan ikon default aplikasi
    );

    // Pengaturan untuk iOS (meminta izin)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inisialisasi plugin
    await _notificationsPlugin.initialize(initializationSettings);
    print("[NOTIF HELPER] ✅ Inisialisasi selesai.");

    // Minta izin Android 13+
    // Minta izin 'POST_NOTIFICATIONS' yang kita tambahkan di AndroidManifest
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Fungsi untuk menampilkan notifikasi INSTANT ketika jurnal tersimpan
  Future<void> showJournalSavedNotification() async {
    print("[NOTIF HELPER] 📝 Menampilkan notifikasi: Jurnal tersimpan");
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'journal_saved_channel',
      'Jurnal Tersimpan',
      channelDescription: 'Notifikasi ketika jurnal baru berhasil tersimpan',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Gunakan timestamp untuk ID unik
    int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    await _notificationsPlugin.show(
      notificationId,
      '📝 Jurnal Tersimpan!',
      'Jurnal perjalanan baru Anda telah tersimpan dengan sukses.',
      notificationDetails,
    );
      print("[NOTIF HELPER] ✅ Notifikasi jurnal tersimpan ditampilkan.");
  }

  // Fungsi untuk menampilkan notifikasi INSTANT dengan custom title dan body
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print("[NOTIF HELPER] 🔔 Menampilkan notifikasi instant: $title");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_notification_channel',
      'Notifikasi Instant',
      channelDescription: 'Notifikasi instant dari aplikasi',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );    print("[NOTIF HELPER] ✅ Notifikasi instant ditampilkan.");
  }

  // Fungsi untuk menampilkan notifikasi MILESTONE (Pencapaian)
  Future<void> showMilestoneNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print("[NOTIF HELPER] 🎉 Menampilkan notifikasi milestone: $title");    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'milestone_notification_channel',
      'Milestone & Pencapaian',
      channelDescription: 'Notifikasi pencapaian dan milestone dari aplikasi',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );

    print("[NOTIF HELPER] ✅ Notifikasi milestone ditampilkan.");
  }
}