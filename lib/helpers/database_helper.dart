import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "jejakpena_multiuser.db"; 
  static const _databaseVersion = 1;
  
  static const tableUsers = 'users';
  static const columnUserId = 'id';
  static const columnUsername = 'username';
  static const columnPassword = 'password'; 

  static const table = 'JournalEntry';
  static const columnId = 'id';
  static const columnJudul = 'judul';
  static const columnCerita = 'cerita';
  static const columnTanggal = 'tanggal';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnNamaLokasi = 'nama_lokasi';
  static const columnJournalUserId = 'user_id';

  static const tablePhotos = 'JournalPhotos';
  static const columnPhotoId = 'id';
  static const columnPhotoJournalId = 'id_jurnal_entry';
  static const columnPhotoPath = 'path_foto';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableUsers (
          $columnUserId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnUsername TEXT NOT NULL UNIQUE,
          $columnPassword TEXT NOT NULL
        )
        ''');

    await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnJudul TEXT NOT NULL,
          $columnCerita TEXT,
          $columnTanggal TEXT NOT NULL,
          $columnLatitude REAL, 
          $columnLongitude REAL,
          $columnNamaLokasi TEXT,
          $columnJournalUserId INTEGER NOT NULL,
          FOREIGN KEY ($columnJournalUserId) REFERENCES $tableUsers ($columnUserId) ON DELETE CASCADE
        )
        ''');

    await db.execute('''
        CREATE TABLE $tablePhotos (
          $columnPhotoId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnPhotoJournalId INTEGER NOT NULL,
          $columnPhotoPath TEXT NOT NULL,
          FOREIGN KEY ($columnPhotoJournalId) REFERENCES $table ($columnId) ON DELETE CASCADE 
        )
        ''');
  }

  Future<int> registerUser(String username, String password) async {
    Database db = await instance.database;
    try {
      return await db.insert(tableUsers, {
        columnUsername: username,
        columnPassword: password,
      });
    } catch (e) {
      print("Register Error: $e");
      return -1;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: '$columnUsername = ? AND $columnPassword = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> createJournal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> getJournalsForUser(int userId) async {
    Database db = await instance.database;
    return await db.query(
      table,
      where: '$columnJournalUserId = ?',
      whereArgs: [userId],
      orderBy: '$columnId DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getJournalsForUserWithPhotoCount(int userId) async {
    Database db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        J.*, 
        COUNT(P.$columnPhotoId) as photo_count 
      FROM 
        $table AS J
      LEFT JOIN 
        $tablePhotos AS P ON J.$columnId = P.$columnPhotoJournalId
      WHERE
        J.$columnJournalUserId = ?
      GROUP BY 
        J.$columnId
      ORDER BY 
        J.$columnId DESC
    ''', [userId]);

    return maps;
  }

  Future<int> updateJournal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteJournal(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

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

  Future<int> createJournalPhoto(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tablePhotos, row);
  }

  Future<List<Map<String, dynamic>>> getPhotosForJournal(int journalId) async {
    Database db = await instance.database;
    return await db.query(
      tablePhotos,
      where: '$columnPhotoJournalId = ?',
      whereArgs: [journalId],
    );
  }

  Future<int> deletePhoto(int photoId) async {
    Database db = await instance.database;
    return await db.delete(
      tablePhotos,
      where: '$columnPhotoId = ?',
      whereArgs: [photoId],
    );
  }
}