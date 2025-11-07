import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/notification_helper.dart';
import '../helpers/milestone_helper.dart';
import '../helpers/location_helper.dart';
import 'location_picker_page.dart';
import 'package:intl/intl.dart';
import '../helpers/user_session.dart';

class AddJournalPage extends StatefulWidget {
  const AddJournalPage({super.key});

  @override
  State<AddJournalPage> createState() => _AddJournalPageState();
}

class _AddJournalPageState extends State<AddJournalPage> {
  final _notificationHelper = NotificationHelper.instance;
  final _judulController = TextEditingController();
  final _ceritaController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;
  
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _addressString = "Mendeteksi lokasi...";
  bool _useAutoLocation = true;

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imagePaths.add(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengambil gambar: $e"),
          backgroundColor: const Color(0xFFFF6B4A),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _addressString = "Mendeteksi lokasi...";
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _addressString = "Izin lokasi ditolak.";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await LocationHelper.getAddressFromPosition(position);
      setState(() {
        _currentPosition = position;
        _addressString = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _addressString = "Gagal mendapatkan lokasi: ${e.toString()}";
        _isLoadingLocation = false;
      });
    }
  }

  void _useAutoLocationMode() {
    setState(() {
      _useAutoLocation = true;
    });
    _getCurrentLocation();
  }

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
        _useAutoLocation = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B4A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveJournal() async {
    String judul = _judulController.text;
    String cerita = _ceritaController.text;

    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong!'),
          backgroundColor: Color(0xFFFF6B4A),
        ),
      );
      return;
    }

    String tanggal = _selectedDate.toIso8601String();

    final userId = UserSession.instance.currentUserId;
    if (userId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sesi login. Silakan login ulang.')));
       return;
    }

    Map<String, dynamic> journalRow = {
      DatabaseHelper.columnJudul: judul,
      DatabaseHelper.columnCerita: cerita,
      DatabaseHelper.columnTanggal: tanggal,
      DatabaseHelper.columnLatitude: _currentPosition?.latitude,
      DatabaseHelper.columnLongitude: _currentPosition?.longitude,
      DatabaseHelper.columnNamaLokasi: _addressString,
      DatabaseHelper.columnJournalUserId: userId,
    };

    final journalId = await dbHelper.createJournal(journalRow);
    
    for (String path in _imagePaths) {
      Map<String, dynamic> photoRow = {
        DatabaseHelper.columnPhotoJournalId: journalId,
        DatabaseHelper.columnPhotoPath: path,
      };
      await dbHelper.createJournalPhoto(photoRow);
    }
    
    await _notificationHelper.showJournalSavedNotification();

    final milestoneHelper = MilestoneHelper();
    final activeMilestones = await milestoneHelper.checkAllMilestones();
    
    for (var milestone in activeMilestones) {
      final type = milestone['type'] as String;
      final milestoneNumber = milestone['milestone'] as int;
      
      final title = milestoneHelper.generateMilestoneText(type, milestoneNumber);
      final subtitle = milestoneHelper.generateMilestoneSubtitle(type, milestoneNumber);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _notificationHelper.showMilestoneNotification(
        id: DateTime.now().millisecondsSinceEpoch.toInt() % 100000,
        title: title,
        body: subtitle,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _ceritaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B4A),
        foregroundColor: Colors.white,
        title: const Text('Jurnal Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveJournal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B4A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6B4A).withOpacity(0.3)),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF6B4A),
                          ),
                        ),
                      if (!_isLoadingLocation && _currentPosition != null)
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF6B4A),
                          size: 20,
                        ),
                      if (!_isLoadingLocation && _currentPosition == null)
                        const Icon(
                          Icons.location_off,
                          color: Colors.grey,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _addressString,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text("Auto Lokasi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useAutoLocation 
                                ? const Color(0xFFFF6B4A) 
                                : Colors.grey[300],
                            foregroundColor: _useAutoLocation 
                                ? Colors.white 
                                : Colors.grey[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _useAutoLocationMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text("Pilih di Peta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_useAutoLocation 
                                ? const Color(0xFFFF6B4A) 
                                : Colors.white,
                            foregroundColor: !_useAutoLocation 
                                ? Colors.white 
                                : const Color(0xFFFF6B4A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _openLocationPicker,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _judulController,
                    decoration: InputDecoration(
                      labelText: 'Judul',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF6B4A), width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ceritaController,
                    decoration: InputDecoration(
                      labelText: 'Cerita Anda...',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF6B4A), width: 2),
                      ),
                    ),
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Jurnal',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d MMMM yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_today, color: Color(0xFFFF6B4A)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Foto Jurnal",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_imagePaths.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_imagePaths[index]),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6B4A),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(6),
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

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Kamera"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Galeri"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}