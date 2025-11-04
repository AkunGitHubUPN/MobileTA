import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  bool _isEditMode = false; // Toggle edit mode
  // Controllers untuk edit
  late TextEditingController _judulController;
  late TextEditingController _ceritaController;
  List<String> _photosToDelete = []; // Foto yang akan dihapus
  List<String> _newPhotoPaths = []; // Foto baru yang ditambahkan
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController();
    _ceritaController = TextEditingController();
    _loadJournalData();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _ceritaController.dispose();
    super.dispose();
  }

  void _loadJournalData() async {
    // Ambil data jurnal DAN data foto
    final journalData = await dbHelper.getJournalById(widget.journalId);
    final photoData = await dbHelper.getPhotosForJournal(widget.journalId);

    setState(() {
      _journal = journalData;
      _photos = photoData;
      _judulController.text = journalData?[DatabaseHelper.columnJudul] ?? '';
      _ceritaController.text = journalData?[DatabaseHelper.columnCerita] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    try {
      // Update jurnal
      Map<String, dynamic> updatedJournal = {
        DatabaseHelper.columnId: widget.journalId,
        DatabaseHelper.columnJudul: _judulController.text,
        DatabaseHelper.columnCerita: _ceritaController.text,
        DatabaseHelper.columnTanggal: _journal![DatabaseHelper.columnTanggal],
        DatabaseHelper.columnLatitude: _journal![DatabaseHelper.columnLatitude],
        DatabaseHelper.columnLongitude:
            _journal![DatabaseHelper.columnLongitude],
        DatabaseHelper.columnNamaLokasi: _journal![DatabaseHelper.columnNamaLokasi],
      };      await dbHelper.updateJournal(updatedJournal);

      // Hapus foto yang ditandai
      for (String photoPath in _photosToDelete) {
        final photo = _photos.firstWhere(
          (p) => p[DatabaseHelper.columnPhotoPath] == photoPath,
          orElse: () => {},
        );
        if (photo.isNotEmpty) {
          await dbHelper.deletePhoto(photo[DatabaseHelper.columnPhotoId]);
        }
      }

      // Tambahkan foto baru
      for (String newPhotoPath in _newPhotoPaths) {
        Map<String, dynamic> photoRow = {
          DatabaseHelper.columnPhotoJournalId: widget.journalId,
          DatabaseHelper.columnPhotoPath: newPhotoPath,
        };
        await dbHelper.createJournalPhoto(photoRow);
      }

      // Reload data
      _photosToDelete.clear();
      _newPhotoPaths.clear();
      _loadJournalData();
      
      setState(() {
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jurnal berhasil diperbarui'),
            backgroundColor: Color(0xFFFF6B4A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  void _togglePhotoForDelete(String photoPath) {
    setState(() {
      if (_photosToDelete.contains(photoPath)) {
        _photosToDelete.remove(photoPath);
      } else {
        _photosToDelete.add(photoPath);
      }
    });
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _newPhotoPaths.add(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil gambar: $e"),
            backgroundColor: const Color(0xFFFF6B4A),
          ),
        );
      }
    }
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

    // Format tanggal untuk tampilan yang lebih rapi
    String tanggal = _journal![DatabaseHelper.columnTanggal];
    String tanggalFormatted = tanggal.substring(0, 10); // YYYY-MM-DD
    
    // Parse lokasi untuk menampilkan dengan lebih rapi
    String locationName =
        _journal![DatabaseHelper.columnNamaLokasi] ?? "Lokasi Tidak Diketahui";
    List<String> parts = locationName.split(',');
    if (parts.length >= 3) {
      locationName =
          "${parts[parts.length - 3].trim()}, ${parts[parts.length - 1].trim()}";
    }    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_journal![DatabaseHelper.columnJudul]),
        backgroundColor: const Color(0xFFFF6B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_isEditMode ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_isEditMode) {
              // Batalkan edit mode
              setState(() {
                _isEditMode = false;
                _photosToDelete.clear();
                _loadJournalData(); // Reload data untuk reset form
              });
            } else {
              // Kembali ke page sebelumnya
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),            // --- GALERI FOTO ---
            if (_photos.isNotEmpty || _newPhotoPaths.isNotEmpty)
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length + _newPhotoPaths.length + (_isEditMode ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Tombol tambah foto di akhir (hanya saat edit mode)
                    if (_isEditMode && index == _photos.length + _newPhotoPaths.length) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 16 : 8,
                          right: 16,
                        ),
                        child: GestureDetector(
                          onTap: _pickPhotoFromGallery,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B4A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF6B4A),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 60,
                                  color: Color(0xFFFF6B4A),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tambah Foto',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B4A),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Ambil path foto (dari _photos atau _newPhotoPaths)
                    String path;
                    bool isNewPhoto = index >= _photos.length;
                    if (isNewPhoto) {
                      path = _newPhotoPaths[index - _photos.length];
                    } else {
                      path = _photos[index][DatabaseHelper.columnPhotoPath];
                    }

                    bool isMarkedForDelete = _photosToDelete.contains(path);

                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == _photos.length + _newPhotoPaths.length - 1 && !_isEditMode ? 16 : 8,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                              opacity: AlwaysStoppedAnimation(
                                isMarkedForDelete ? 0.5 : 1.0,
                              ),
                            ),
                          ),
                          // Tanda silang saat edit mode (hanya untuk foto lama)
                          if (_isEditMode && !isNewPhoto)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    _togglePhotoForDelete(path),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isMarkedForDelete
                                        ? Colors.red
                                        : Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close,
                                    color: isMarkedForDelete
                                        ? Colors.white
                                        : Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          // Ikon hapus untuk foto baru
                          if (_isEditMode && isNewPhoto)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _newPhotoPaths.removeAt(index - _photos.length);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // --- KONTEN UTAMA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  // JUDUL
                  if (_isEditMode)
                    TextField(
                      controller: _judulController,
                      decoration: InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6B4A),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6B4A),
                            width: 2,
                          ),
                        ),
                      ),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6B4A),
                      ),
                    )
                  else
                    Text(
                      _journal![DatabaseHelper.columnJudul],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6B4A),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // METADATA CARD (TANGGAL & LOKASI)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B4A).withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TANGGAL
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFFFF6B4A),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tanggalFormatted,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // LOKASI
                        if (_journal![DatabaseHelper.columnNamaLokasi] !=
                            null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Color(0xFFFF6B4A),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  locationName,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CERITA SECTION TITLE
                  Text(
                    'Cerita Pena',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B4A),
                    ),
                  ),                  const SizedBox(height: 12),                  // CERITA CONTENT
                  if (_isEditMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: TextField(
                        controller: _ceritaController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Cerita Perjalanan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B4A),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B4A),
                              width: 2,
                            ),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF6B4A).withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _journal![DatabaseHelper.columnCerita],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
