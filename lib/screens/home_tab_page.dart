import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// --- BARU ---
// Import plugin lokasi
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
// Import geolocator untuk membuat stream
import 'package:geolocator/geolocator.dart';
// ---
import '../helpers/database_helper.dart';
import 'add_journal_page.dart';
import 'journal_detail_page.dart';

// Enum untuk opsi sorting
enum SortOption { terbaru, terlama }

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => HomeTabPageState();
}

class HomeTabPageState extends State<HomeTabPage> {
  final dbHelper = DatabaseHelper.instance;

  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allJournals = [];
  List<Map<String, dynamic>> _filteredJournals = [];

  bool _isLoading = true;

  // Variabel untuk menyimpan status filter
  SortOption _currentSort = SortOption.terbaru;
  bool _filterHanyaFoto = false;
  bool _filterHanyaLokasi = false;

  // --- BARU ---
  // Stream untuk menampung data lokasi
  Stream<LocationMarkerPosition>? _positionStream;
  bool _isLocationPermissionGranted = false;

  // Getter untuk mengecek apakah ada filter yang aktif
  bool get _isFilterActive =>
      _currentSort != SortOption.terbaru ||
      _filterHanyaFoto ||
      _filterHanyaLokasi;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applySearchAndFilters);
    // --- BARU ---
    // Cek izin dan aktifkan stream lokasi
    _checkLocationPermission();
  }

  // --- BARU ---
  // Fungsi untuk cek izin & inisialisasi stream
  Future<void> _checkLocationPermission() async {
    // Cek izin
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Jika ditolak, minta izin
      permission = await Geolocator.requestPermission();
    }

    // Cek hasil akhir
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _isLocationPermissionGranted = false;
      });
      // Beri tahu user jika izin ditolak
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Izin lokasi ditolak. Titik lokasi tidak akan tampil.')));
      }
    } else {
      // Jika izin diberikan
      setState(() {
        _isLocationPermissionGranted = true;
        // Buat stream posisi
        _positionStream = Geolocator.getPositionStream(
          // Atur akurasi dan interval
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update setiap 10 meter
          ),
        ).map(
          (Position position) {
            // Ubah data 'Position' dari geolocator
            // menjadi data 'LocationMarkerPosition' untuk plugin peta
            return LocationMarkerPosition(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            );
          },
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearchAndFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final data = await dbHelper.getAllJournalsWithPhotoCount();
    setState(() {
      _allJournals = data;
      // Reset filter saat data dimuat ulang
      _currentSort = SortOption.terbaru;
      _filterHanyaFoto = false;
      _filterHanyaLokasi = false;
      _isLoading = false;
    });
    // Terapkan filter (termasuk search query yg mungkin masih ada)
    _applySearchAndFilters();
  }

  void _applySearchAndFilters() {
    List<Map<String, dynamic>> tempJournals = List.from(_allJournals);

    // 1. Terapkan SORTING
    if (_currentSort == SortOption.terlama) {
      tempJournals = tempJournals.reversed.toList();
    }

    // 2. Terapkan FILTER FOTO
    if (_filterHanyaFoto) {
      tempJournals = tempJournals.where((j) {
        return (j['photo_count'] as int) > 0;
      }).toList();
    }

    // 3. Terapkan FILTER LOKASI
    if (_filterHanyaLokasi) {
      tempJournals = tempJournals.where((j) {
        return j[DatabaseHelper.columnLatitude] != null;
      }).toList();
    }

    // 4. Terapkan SEARCH
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempJournals = tempJournals.where((journal) {
        final title =
            journal[DatabaseHelper.columnJudul].toString().toLowerCase();
        return title.contains(query);
      }).toList();
    }

    // 5. Update UI
    setState(() {
      _filteredJournals = tempJournals;
    });
  }

  Future<void> _onAddJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddJournalPage()),
    );
    _loadData();
    _searchController.clear();
  }

  void _openDetail(int journalId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalDetailPage(journalId: journalId),
      ),
    );
  }

  void _showFilterBottomSheet() {
    SortOption tempSort = _currentSort;
    bool tempFoto = _filterHanyaFoto;
    bool tempLokasi = _filterHanyaLokasi;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urutkan Berdasarkan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  RadioListTile<SortOption>(
                    title: const Text('Jurnal Terbaru'),
                    value: SortOption.terbaru,
                    groupValue: tempSort,
                    onChanged: (val) {
                      setModalState(() {
                        tempSort = val!;
                      });
                    },
                  ),
                  RadioListTile<SortOption>(
                    title: const Text('Jurnal Terlama'),
                    value: SortOption.terlama,
                    groupValue: tempSort,
                    onChanged: (val) {
                      setModalState(() {
                        tempSort = val!;
                      });
                    },
                  ),
                  const Divider(),
                  Text(
                    'Filter',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SwitchListTile(
                    title: const Text('Hanya tampilkan yang memiliki foto'),
                    value: tempFoto,
                    onChanged: (val) {
                      setModalState(() {
                        tempFoto = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Hanya tampilkan yang memiliki lokasi'),
                    value: tempLokasi,
                    onChanged: (val) {
                      setModalState(() {
                        tempLokasi = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentSort = tempSort;
                            _filterHanyaFoto = tempFoto;
                            _filterHanyaLokasi = tempLokasi;
                          });
                          _applySearchAndFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Terapkan'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari Jurnal...',
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _isFilterActive ? Colors.indigo : null,
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddJournal,
        child: const Icon(Icons.add),
      ),      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- TINGGI MAP: 70% dari tinggi layar (flex: 7) ---
                Expanded(
                  flex: 6,
                  child: _buildMapSection(),
                ),
                // --- TINGGI DAFTAR JURNAL: 30% dari tinggi layar (flex: 3) ---
                Expanded(
                  flex: 4,
                  child: _buildJournalListSection(),
                ),
              ],
            ),
    );
  }
  Widget _buildMapSection() {
    List<Marker> markers = _filteredJournals.map((journal) {
      if (journal[DatabaseHelper.columnLatitude] == null) {
        return null;
      }
      int photoCount = journal['photo_count'];

      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(
          journal[DatabaseHelper.columnLatitude],
          journal[DatabaseHelper.columnLongitude],
        ),
        child: GestureDetector(
          onTap: () {
            _openDetail(journal[DatabaseHelper.columnId]);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_pin, color: Colors.red, size: 45),
              if (photoCount > 0)
                Positioned(
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ]),
                    child: Text(
                      '$photoCount',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();

    final mapController = MapController();

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(-2.5489, 118.0149),
            initialZoom: 5.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: markers),
            // --- MODIFIKASI ---
            // Tampilkan layer lokasi HANYA jika izin diberikan
            // dan stream sudah siap
            if (_isLocationPermissionGranted && _positionStream != null)
              CurrentLocationLayer(
                // Berikan stream-nya ke parameter 'positionStream'
                positionStream: _positionStream!,
              ),
          ],
        ),        // --- TOMBOL ZOOM IN dan ZOOM OUT (HORIZONTAL) ---
        Positioned(
          right: 16,
          bottom: 16,
          child: Row(
            children: [
              // Tombol Zoom Out
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_out',
                backgroundColor: Colors.indigo,
                onPressed: () {
                  mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove, color: Colors.white),
              ),
              const SizedBox(width: 8),
              // Tombol Zoom In
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_in',
                backgroundColor: Colors.indigo,
                onPressed: () {
                  mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJournalListSection() {
    if (_filteredJournals.isEmpty) {
      if (_searchController.text.isNotEmpty || _isFilterActive) {
        return const Center(child: Text("Jurnal tidak ditemukan."));
      }
      return const Center(child: Text("Belum ada jurnal."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredJournals.length,
      itemBuilder: (context, index) {
        final journal = _filteredJournals[index];
        final photoCount = journal['photo_count'];

        String locationName =
            journal[DatabaseHelper.columnNamaLokasi] ?? "Lokasi Tidak Diketahui";
        List<String> parts = locationName.split(',');
        if (parts.length >= 3) {
          locationName =
              "${parts[parts.length - 3].trim()}, ${parts[parts.length - 1].trim()}";
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(journal[DatabaseHelper.columnJudul]),
            subtitle: Text(
                "${journal[DatabaseHelper.columnTanggal].substring(0, 10)} | $locationName"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library,
                      color: Colors.indigo, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$photoCount',
                    style: const TextStyle(
                        color: Colors.indigo, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            onTap: () {
              _openDetail(journal[DatabaseHelper.columnId]);
            },
          ),
        );
      },
    );
  }
}