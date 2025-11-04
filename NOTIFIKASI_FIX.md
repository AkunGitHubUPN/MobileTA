# 🔧 Analisis & Solusi Masalah Notifikasi

## **Masalah yang Ditemukan**

### 1. ❌ **ID Notifikasi Hardcoded ke 0**
**Lokasi:** `notification_helper.dart` baris 85
```dart
await _notificationsPlugin.zonedSchedule(
  0,  // ← MASALAH! Semua notifikasi punya ID sama
  ...
);
```

**Dampak:**
- Setiap notifikasi baru akan menimpa yang sebelumnya
- Log menunjukkan: Notifikasi jam 8:00 PM tertimpa oleh jam 6:09 PM
- Hanya 1 notifikasi yang bisa "hidup" pada waktu tertentu

**Solusi:** Gunakan ID unik berdasarkan jam
```dart
int notificationId = time.hour * 60 + time.minute;
// Contoh: jam 20:00 → ID 1200, jam 6:09 → ID 369
```

---

### 2. ⚠️ **Emulator Android Studio Tidak Tampilkan Notifikasi Jadwal di Debug Mode**

**Penyebab:**
- Notifikasi jadwal (`zonedSchedule`) tidak ditampilkan saat app berjalan aktif
- Emulator Android Studio terkadang memiliki masalah dengan notification scheduling

**Solusi:**
- ✅ **Minimize atau Close aplikasi** → notifikasi akan muncul di notification bar
- ✅ **Gunakan instant notification untuk testing** (sudah ditambahkan)
- ✅ **Test di device fisik** (lebih reliable)

---

### 3. 🕐 **Timezone & Waktu Scheduling**

**Kode sekarang:**
```dart
if (scheduledDate.isBefore(now)) {
  scheduledDate = scheduledDate.add(const Duration(days: 1));
}
```

**Artinya:**
- Jika Anda set jam 20:00 tapi sudah lewat jam 20:00, notifikasi akan dijadwalkan untuk besok
- Ini **BENAR** dan sesuai harapan

---

## **Perbaikan yang Dilakukan**

### ✅ File: `notification_helper.dart`

1. **Ganti ID dari 0 ke ID unik:**
   ```dart
   int notificationId = time.hour * 60 + time.minute;
   ```

2. **Tambahkan logging untuk debugging:**
   ```dart
   print("[NOTIF HELPER] Menjadwalkan notifikasi ID=$notificationId untuk: $scheduledDate");
   ```

3. **Tambahkan fungsi instant notification:**
   ```dart
   Future<void> showInstantNotification({...})
   ```

### ✅ File: `settings_page.dart`

1. **Tambahkan tombol "Test Notifikasi Instant"** untuk testing tanpa menunggu jadwal

---

## **Cara Testing**

### **1️⃣ Test Instant Notification (Recommended)**
1. Buka aplikasi
2. Pergi ke tab **Pengaturan**
3. Aktifkan **"Aktifkan Notifikasi Harian"**
4. Klik **"🧪 Test Notifikasi Instant"**
5. Minimize app → **Notifikasi akan muncul di notification bar**

### **2️⃣ Test Jadwal Notifikasi**
1. Di Pengaturan, set waktu ke **5 menit ke depan** (misal sekarang 6:04 PM, set ke 6:09 PM)
2. Klik **Save**
3. **Minimize atau Close app**
4. Tunggu 5 menit → Notifikasi akan muncul

### **3️⃣ Debug Log**
Lihat output terminal flutter untuk melihat log:
```
I/flutter ( 6951): [NOTIF HELPER] Menjadwalkan notifikasi ID=1200 untuk: 2025-11-05 20:00:00.000+0700
I/flutter ( 6951): [NOTIF HELPER] Notifikasi berhasil dijadwalkan.
```

---

## **Checklist Emulator Android Studio**

Pastikan emulator Anda sudah:
- ✅ Minimum API level 31 (untuk notification scheduling)
- ✅ Izin POST_NOTIFICATIONS diminta (sudah ada di `main.dart`)
- ✅ App notification channel sudah terdaftar (sudah ada di `init()`)

---

## **Troubleshooting**

| Masalah | Solusi |
|---------|--------|
| Notifikasi tidak muncul saat app aktif | Minimize/Close app |
| Notifikasi terlalu banyak | ID duplikat sudah diperbaiki ✅ |
| Jam notifikasi salah | Cek timezone di emulator: Settings → System → Date & time |
| Notifikasi tidak ada sama sekali | Cek izin di `AndroidManifest.xml` sudah ada `POST_NOTIFICATIONS` |

---

## **File yang Dimodifikasi**

1. ✅ `lib/helpers/notification_helper.dart` - Fix ID + logging + instant notification
2. ✅ `lib/screens/settings_page.dart` - Tambah tombol test

