import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/notification_helper.dart';
import '../helpers/milestone_helper.dart';
import 'location_picker_page.dart';
import 'package:intl/intl.dart';

class AddJournalPage extends StatefulWidget {
  const AddJournalPage({super.key});

  @override
  State<AddJournalPage> createState() => _AddJournalPageState();
}

class _AddJournalPageState extends State<AddJournalPage> {
  final _notificationHelper = NotificationHelper.instance;
  // Controller untuk mengambil teks dari input field
  final _judulController = TextEditingController();
  final _ceritaController = TextEditingController();

  // Panggil db helper
  final dbHelper = DatabaseHelper.instance;
  Position? _currentPosition; // Untuk menyimpan data posisi
  bool _isLoadingLocation = false; // Untuk penanda loading
  String _addressString = "Mendeteksi lokasi...";
  bool _useAutoLocation = true; // Flag untuk auto atau manual lokasi

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  
  // --- TAMBAHAN UNTUK TANGGAL ---
  DateTime _selectedDate = DateTime.now(); // Default tanggal hari ini

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  // --- TAMBAHKAN FUNGSI BARU INI ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Kompres sedikit
      );

      if (pickedFile != null) {
        setState(() {
          _imagePaths.add(pickedFile.path); // Tambah path ke list
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengambil gambar: $e")));
    }
  }

  // Fungsi untuk menghapus foto
  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<String> _getAddressFromCoords(Position position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}',
      );

      // Kirim request GET
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'jejak_pena_app', // API Nominatim butuh User-Agent
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ambil nama tampilan yang mudah dibaca
        return data['display_name'] ?? 'Lokasi tidak dikenal';
      } else {
        return 'Gagal mengambil nama lokasi';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
  // --- TAMBAHKAN FUNGSI BARU INI ---
  void _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _addressString = "Mendeteksi lokasi...";
    });

    try {
      // 1. Cek izin
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // 2. Jika ditolak, minta izin
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _addressString = "Izin lokasi ditolak.";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // 3. Jika izin diberikan, ambil lokasi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = await _getAddressFromCoords(position);
      setState(() {
        _currentPosition = position;
        _addressString = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _addressString = "Gagal mendapatkan lokasi: ${e.toString()}";
        _isLoadingLocation = false;
      });    }
  }

  // Fungsi untuk mode auto lokasi
  void _useAutoLocationMode() {
    setState(() {
      _useAutoLocation = true;
    });
    _getCurrentLocation();
  }
  // Fungsi untuk membuka location picker (memilih lokasi manual)
  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialPosition: _currentPosition,
        ),
      ),
    );

    if (result != null) {
      final position = result['position'] as Position;
      final address = result['address'] as String;

      setState(() {
        _currentPosition = position;
        _addressString = address;
        _useAutoLocation = false; // Tandai bahwa user memilih manual
      });
    }
  }

  // --- FUNGSI UNTUK MEMILIH TANGGAL ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Tanggal awal
      lastDate: DateTime.now(), // Tidak boleh lebih dari hari ini
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }  void _saveJournal() async {
    String judul = _judulController.text;
    String cerita = _ceritaController.text;

    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong!')),
      );
      return;
    }

    // Gunakan tanggal yang dipilih oleh user
    String tanggal = _selectedDate.toIso8601String();

    // --- LANGKAH 1: SIMPAN JURNAL INDUK ---
    Map<String, dynamic> journalRow = {
      DatabaseHelper.columnJudul: judul,
      DatabaseHelper.columnCerita: cerita,
      DatabaseHelper.columnTanggal: tanggal,
      DatabaseHelper.columnLatitude: _currentPosition?.latitude,
      DatabaseHelper.columnLongitude: _currentPosition?.longitude,
      DatabaseHelper.columnNamaLokasi: _addressString,
    };

    // Simpan jurnal dan dapatkan ID-nya
    final journalId = await dbHelper.createJournal(journalRow);
    
    // --- LANGKAH 2: SIMPAN FOTO-FOTO ---
    for (String path in _imagePaths) {
      Map<String, dynamic> photoRow = {
        DatabaseHelper.columnPhotoJournalId: journalId, // Tautkan ke ID Jurnal
        DatabaseHelper.columnPhotoPath: path,
      };
      await dbHelper.createJournalPhoto(photoRow);
    }
    
    // --- LANGKAH 3: TAMPILKAN NOTIFIKASI JURNAL TERSIMPAN ---
    await _notificationHelper.showJournalSavedNotification();

    // --- LANGKAH 4: CEK MILESTONE ---
    final milestoneHelper = MilestoneHelper();
    final activeMilestones = await milestoneHelper.checkAllMilestones();
    
    // Tampilkan notifikasi untuk setiap milestone yang dicapai
    for (var milestone in activeMilestones) {
      final type = milestone['type'] as String;
      final milestoneNumber = milestone['milestone'] as int;
      
      final title = milestoneHelper.generateMilestoneText(type, milestoneNumber);
      final subtitle = milestoneHelper.generateMilestoneSubtitle(type, milestoneNumber);
      
      // Delay sedikit agar notifikasi tidak overlap
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _notificationHelper.showMilestoneNotification(
        id: DateTime.now().millisecondsSinceEpoch.toInt() % 100000,
        title: title,
        body: subtitle,
      );
    }

    if (mounted) {
      Navigator.pop(context); // Kembali ke home
    }
  }

  // Selalu dispose controller setelah tidak dipakai
  @override
  void dispose() {
    _judulController.dispose();
    _ceritaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Baru'),
        actions: [
          // Tambahkan tombol "Simpan" di AppBar
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveJournal, // Panggil fungsi simpan
          ),
        ],
      ),      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // BAGIAN LOKASI
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLoadingLocation)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (!_isLoadingLocation && _currentPosition != null)
                          const Icon(
                            Icons.location_on,
                            color: Colors.indigo,
                            size: 20,
                          ),
                        if (!_isLoadingLocation && _currentPosition == null)
                          const Icon(
                            Icons.location_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        // Tampilkan pesan status
                        Expanded(child: Text(_addressString)),
                      ],
                    ),                    const SizedBox(height: 12),
                    // Tombol untuk mengubah mode lokasi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.my_location),
                          label: const Text("Auto Lokasi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useAutoLocation ? Colors.indigo : Colors.grey,
                          ),
                          onPressed: _useAutoLocationMode,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text("Pilih di Peta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_useAutoLocation ? Colors.indigo : Colors.grey,
                          ),
                          onPressed: _openLocationPicker,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Input field untuk Judul
              TextField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),              const SizedBox(height: 16),
              // Input field untuk Cerita
              TextField(
                controller: _ceritaController,
                decoration: const InputDecoration(
                  labelText: 'Cerita Anda...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10, // Buat field lebih besar
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              // --- BAGIAN INPUT TANGGAL ---
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Jurnal',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),                          Text(
                            DateFormat('d MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today, color: Colors.indigo),
                    ],
                  ),
                ),
              ),              
              const SizedBox(height: 40),
              const Text(
                "Foto Jurnal",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Preview foto dengan tombol hapus
              if (_imagePaths.isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            // Foto
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePaths[index]),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Tombol Hapus (X)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // Tombol-tombol untuk ambil foto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Kamera"),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galeri"),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
