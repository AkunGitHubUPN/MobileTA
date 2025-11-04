import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import '../helpers/database_helper.dart';
import 'add_journal_page.dart';
import 'journal_detail_page.dart';

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

  SortOption _currentSort = SortOption.terbaru;
  bool _filterHanyaFoto = false;
  bool _filterHanyaLokasi = false;

  Stream<LocationMarkerPosition>? _positionStream;
  bool _isLocationPermissionGranted = false;

  bool get _isFilterActive =>
      _currentSort != SortOption.terbaru ||
      _filterHanyaFoto ||
      _filterHanyaLokasi;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applySearchAndFilters);
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _isLocationPermissionGranted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Izin lokasi ditolak. Titik lokasi tidak akan tampil.')));
      }
    } else {
      setState(() {
        _isLocationPermissionGranted = true;
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).map(
          (Position position) {
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
      _currentSort = SortOption.terbaru;
      _filterHanyaFoto = false;
      _filterHanyaLokasi = false;
      _isLoading = false;
    });
    _applySearchAndFilters();
  }

  void _applySearchAndFilters() {
    List<Map<String, dynamic>> tempJournals = List.from(_allJournals);

    if (_currentSort == SortOption.terlama) {
      tempJournals = tempJournals.reversed.toList();
    }

    if (_filterHanyaFoto) {
      tempJournals = tempJournals.where((j) {
        return (j['photo_count'] as int) > 0;
      }).toList();
    }

    if (_filterHanyaLokasi) {
      tempJournals = tempJournals.where((j) {
        return j[DatabaseHelper.columnLatitude] != null;
      }).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempJournals = tempJournals.where((journal) {
        final title =
            journal[DatabaseHelper.columnJudul].toString().toLowerCase();
        return title.contains(query);
      }).toList();
    }

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urutkan Berdasarkan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RadioListTile<SortOption>(
                    title: const Text('Jurnal Terbaru'),
                    value: SortOption.terbaru,
                    groupValue: tempSort,
                    activeColor: const Color(0xFFFF6B4A),
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
                    activeColor: const Color(0xFFFF6B4A),
                    onChanged: (val) {
                      setModalState(() {
                        tempSort = val!;
                      });
                    },
                  ),
                  const Divider(),
                  Text(
                    'Filter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Hanya tampilkan yang memiliki foto'),
                    value: tempFoto,
                    activeColor: const Color(0xFFFF6B4A),
                    onChanged: (val) {
                      setModalState(() {
                        tempFoto = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Hanya tampilkan yang memiliki lokasi'),
                    value: tempLokasi,
                    activeColor: const Color(0xFFFF6B4A),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFFFF6B4A),
            ))
          : Column(
              children: [
                // Header dengan judul
                Container(
                  color: const Color(0xFFFF6B4A),
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perjalan Kamu Sejauh Ini:',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari Jurnal...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.tune,
                                      color: _isFilterActive ? const Color(0xFFFF6B4A) : Colors.grey[700],
                                    ),
                                    onPressed: _showFilterBottomSheet,
                                  ),
                                ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Map Section
                Expanded(
                  flex: 5,
                  child: _buildMapSection(),
                ),
                // Journal List Section
                Expanded(
                  flex: 5,
                  child: _buildJournalListSection(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddJournal,
        backgroundColor: const Color(0xFFFF6B4A),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
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
              const Icon(Icons.location_pin, color: Color(0xFFFF6B4A), size: 45),
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
                        color: Color(0xFFFF6B4A),
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
            if (_isLocationPermissionGranted && _positionStream != null)
              CurrentLocationLayer(
                positionStream: _positionStream!,
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: () {
                  mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add, color: Color(0xFFFF6B4A)),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: () {
                  mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove, color: Color(0xFFFF6B4A)),
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

    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
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

          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                journal[DatabaseHelper.columnJudul],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "${journal[DatabaseHelper.columnTanggal].substring(0, 10)}\n$locationName",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B4A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library,
                        color: Color(0xFFFF6B4A), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$photoCount',
                      style: const TextStyle(
                          color: Color(0xFFFF6B4A), 
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
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
      ),
    );
  }
}