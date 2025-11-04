import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../helpers/database_helper.dart';
import 'journal_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final dbHelper = DatabaseHelper.instance;
  List<Marker> _markers = []; // Daftar pin di peta

  @override
  void initState() {
    super.initState();
    _loadJournalMarkers();
  }

  void refreshMarkers() {
    _loadJournalMarkers();
  }

  void _loadJournalMarkers() async {
    final journals = await dbHelper.getAllJournals();
    List<Marker> loadedMarkers = [];

    for (var journal in journals) {
      // Hanya tambahkan pin jika ada data lat/lon
      if (journal[DatabaseHelper.columnLatitude] != null &&
          journal[DatabaseHelper.columnLongitude] != null) {
        loadedMarkers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(
              journal[DatabaseHelper.columnLatitude],
              journal[DatabaseHelper.columnLongitude],
            ),            child: IconButton(
              icon: const Icon(Icons.location_pin, color: Color(0xFFFF6B4A), size: 35),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JournalDetailPage(
                      journalId: journal[DatabaseHelper.columnId],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = loadedMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(-2.5489, 118.0149), // Pusat peta di Indonesia
        initialZoom: 5.0,
        minZoom: 3.0, 
        maxZoom: 18.0, 
      ),
      children: [
        // Layer 1: Gambar Peta
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        // Layer 2: Pin Jurnal
        MarkerLayer(markers: _markers),
      ],
    );
  }
}
