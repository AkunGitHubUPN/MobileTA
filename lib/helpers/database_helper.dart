// Import paket-paket yang kita butuhkan
import 'dart:io'; // Untuk informasi file & direktori
import 'package:path/path.dart'; // Untuk menggabungkan path
import 'package:sqflite/sqflite.dart'; // Paket SQLite
import 'package:path_provider/path_provider.dart'; // Paket path

// Ini adalah class "juru bicara" database kita
class DatabaseHelper {
  // Nama & versi database
  static const _databaseName = "jejakpena.db";
  static const _databaseVersion = 1;

  // Nama tabel dan kolom-kolomnya
  static const table = 'JournalEntry';
  static const columnId = 'id';
  static const columnJudul = 'judul';
  static const columnCerita = 'cerita';
  static const columnTanggal = 'tanggal';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnNamaLokasi = 'nama_lokasi';
  static const tablePhotos = 'JournalPhotos';
  static const columnPhotoId = 'id';
  static const columnPhotoJournalId = 'id_jurnal_entry';
  static const columnPhotoPath = 'path_foto';

  // --- Bagian Singleton ---
  // Ini adalah trik agar class ini hanya dibuat SATU KALI
  // di seluruh aplikasi. Ini mencegah konflik database.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Variabel untuk menyimpan koneksi database
  static Database? _database;

  // Getter untuk database.
  // Jika database belum ada, panggil _initDatabase() untuk membuatnya.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Fungsi ini menginisialisasi database
  _initDatabase() async {
    // 1. Dapatkan lokasi folder aman untuk menyimpan database
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // 2. Gabungkan lokasi folder dengan nama database kita
    String path = join(documentsDirectory.path, _databaseName);

    // 3. Buka database (atau buat jika belum ada)
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    ); // Panggil _onCreate saat database dibuat pertama kali
  }

  // Fungsi ini dipanggil SAAT database dibuat pertama kali
  // Di sinilah kita mendefinisikan struktur tabel kita
  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnJudul TEXT NOT NULL,
          $columnCerita TEXT,
          $columnTanggal TEXT NOT NULL,
          $columnLatitude REAL, 
          $columnLongitude REAL,
          $columnNamaLokasi TEXT
        )
        ''');

    await db.execute('''
        CREATE TABLE $tablePhotos (
          $columnPhotoId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnPhotoJournalId INTEGER NOT NULL,
          $columnPhotoPath TEXT NOT NULL,
          FOREIGN KEY ($columnPhotoJournalId) REFERENCES $table ($columnId)
            ON DELETE CASCADE 
        )
        ''');
  }

  // --- Fungsi CRUD (Create, Read, Update, Delete) ---

  // 1. CREATE (Membuat Jurnal Baru)
  // Menerima data dalam bentuk Map, lalu menyimpannya ke tabel
  Future<int> createJournal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    // db.insert akan mengembalikan ID dari baris baru yang dibuat
    return await db.insert(table, row);
  }

  // 2. READ (Membaca Semua Jurnal)
  // Mengambil semua data dari tabel dan mengembalikannya sebagai List
  Future<List<Map<String, dynamic>>> getAllJournals() async {
    Database db = await instance.database;
    // Kita urutkan berdasarkan ID terbaru (DESC)
    return await db.query(table, orderBy: '$columnId DESC');
  }

  // 3. UPDATE (Akan kita gunakan nanti di Fase 3)
  Future<int> updateJournal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // 4. DELETE (Akan kita gunakan nanti di Fase 3)
  Future<int> deleteJournal(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // --- TAMBAHKAN FUNGSI BARU UNTUK FOTO ---

  // 1. CREATE (Simpan foto)
  Future<int> createJournalPhoto(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tablePhotos, row);
  }
  // 2. READ (Ambil foto berdasarkan ID jurnal)
  Future<List<Map<String, dynamic>>> getPhotosForJournal(int journalId) async {
    Database db = await instance.database;
    return await db.query(
      tablePhotos,
      where: '$columnPhotoJournalId = ?',
      whereArgs: [journalId],
    );
  }

  // 3. DELETE (Hapus foto berdasarkan ID foto)
  Future<int> deletePhoto(int photoId) async {
    Database db = await instance.database;
    return await db.delete(
      tablePhotos,
      where: '$columnPhotoId = ?',
      whereArgs: [photoId],
    );
  }

  // 3. READ (Ambil 1 jurnal saja) - Kita butuh ini untuk Detail Page
  Future<Map<String, dynamic>?> getJournalById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Fungsi ini akan mengambil semua jurnal DAN menghitung foto
  // yang terhubung dengannya dalam satu kali panggilan.
  Future<List<Map<String, dynamic>>> getAllJournalsWithPhotoCount() async {
    Database db = await instance.database;

    // Ini adalah SQL canggih (LEFT JOIN dengan COUNT)
    // Ini mengambil semua dari JournalEntry (J)
    // dan MENGHITUNG (COUNT) foto (P) yang terhubung
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      J.*, 
      COUNT(P.$columnPhotoId) as photo_count 
    FROM 
      $table AS J
    LEFT JOIN 
      $tablePhotos AS P ON J.$columnId = P.$columnPhotoJournalId
    GROUP BY 
      J.$columnId
    ORDER BY 
      J.$columnId DESC
  ''');

    return maps;
  }
}
