import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'dart:io';

class JournalDetailPage extends StatefulWidget {
  final int journalId; // Halaman ini harus menerima ID Jurnal

  const JournalDetailPage({super.key, required this.journalId});

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> {
  final dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _journal; // Untuk data jurnal (judul, cerita)
  List<Map<String, dynamic>> _photos = []; // Untuk daftar foto
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournalData();
  }

  void _loadJournalData() async {
    // Ambil data jurnal DAN data foto
    final journalData = await dbHelper.getJournalById(widget.journalId);
    final photoData = await dbHelper.getPhotosForJournal(widget.journalId);

    setState(() {
      _journal = journalData;
      _photos = photoData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Memuat...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_journal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Jurnal tidak ditemukan.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_journal![DatabaseHelper.columnJudul])),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 3. TAMPILKAN JUDUL & CERITA
          Text(
            _journal![DatabaseHelper.columnJudul], // JUDUL
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 8),

          // 1. TAMPILKAN GALERI FOTO
          if (_photos.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  String path = _photos[index][DatabaseHelper.columnPhotoPath];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.file(
                      File(path),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // 2. TAMPILKAN METADATA (TANGGAL & LOKASI)
          Text(
            _journal![DatabaseHelper.columnTanggal], // TANGGAL
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          if (_journal![DatabaseHelper.columnNamaLokasi] != null)
            Text(
              _journal![DatabaseHelper.columnNamaLokasi], // LOKASI
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),

          const SizedBox(height: 16),

          Text(
            _journal![DatabaseHelper.columnCerita], // DESKRIPSI
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
