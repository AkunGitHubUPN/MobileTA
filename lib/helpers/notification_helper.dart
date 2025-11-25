import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  NotificationHelper._privateConstructor();
  static final NotificationHelper instance = NotificationHelper._privateConstructor();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<bool> _isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_enabled') ?? true;
  }

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher', 
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    print("[NOTIF HELPER] ✅ Inisialisasi selesai.");

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showJournalSavedNotification() async {

    if (!await _isNotificationEnabled()) {
      print("[NOTIF HELPER] 🔕 Notifikasi dimatikan oleh user. Membatalkan.");
      return;
    }

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

    int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    await _notificationsPlugin.show(
      notificationId,
      '📝 Jurnal Tersimpan!',
      'Jurnal perjalanan baru Anda telah tersimpan dengan sukses.',
      notificationDetails,
    );
    print("[NOTIF HELPER] ✅ Notifikasi jurnal tersimpan ditampilkan.");
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {

    if (!await _isNotificationEnabled()) {
       print("[NOTIF HELPER] 🔕 Notifikasi instant dibatalkan (user disabled).");
       return;
    }

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
    );
    print("[NOTIF HELPER] ✅ Notifikasi instant ditampilkan.");
  }

  Future<void> showMilestoneNotification({
    required int id,
    required String title,
    required String body,
  }) async {

    if (!await _isNotificationEnabled()) {
      print("[NOTIF HELPER] 🔕 Notifikasi milestone dibatalkan (user disabled).");
      return;
    }

    print("[NOTIF HELPER] 🎉 Menampilkan notifikasi milestone: $title");

    const AndroidNotificationDetails androidDetails =
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