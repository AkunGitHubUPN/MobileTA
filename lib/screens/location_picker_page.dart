import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationPickerPage extends StatefulWidget {
  final Position? initialPosition;
  
  const LocationPickerPage({
    super.key,
    this.initialPosition,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = "Pilih lokasi di peta";
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Jika ada initial position, set itu sebagai lokasi awal
    if (widget.initialPosition != null) {
      _selectedLocation = LatLng(
        widget.initialPosition!.latitude,
        widget.initialPosition!.longitude,
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Fungsi untuk mendapatkan nama alamat dari koordinat
  Future<void> _getAddressFromCoords(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = "Mengambil alamat...";
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${location.latitude}&lon=${location.longitude}',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'jejak_pena_app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Lokasi tidak dikenal';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = 'Gagal mengambil nama lokasi';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Error: ${e.toString()}';
        _isLoadingAddress = false;
      });
    }
  }

  // Fungsi untuk zoom in
  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  // Fungsi untuk zoom out
  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  // Fungsi untuk memilih lokasi
  void _confirmLocation() {
    if (_selectedLocation != null) {
      // Return Position object ke halaman sebelumnya
      final position = Position(
        longitude: _selectedLocation!.longitude,
        latitude: _selectedLocation!.latitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      Navigator.pop(context, {
        'position': position,
        'address': _selectedAddress,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi terlebih dahulu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          // Tombol Confirm
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Tetapkan Lokasi',
            onPressed: _confirmLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // PETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(-2.5489, 118.0149),
              initialZoom: 5.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // User klik di peta untuk memilih lokasi
                setState(() {
                  _selectedLocation = point;
                });
                _getAddressFromCoords(point);
              },
            ),
            children: [
              // Layer 1: Tile Layer
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              // Layer 2: Marker untuk lokasi yang dipilih
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _selectedLocation!,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // KONTROL ZOOM (Kiri Bawah)
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              children: [
                // Tombol Zoom In
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.indigo),
                ),
                const SizedBox(height: 8),
                // Tombol Zoom Out
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.indigo),
                ),
              ],
            ),
          ),

          // INFO LOKASI (Bawah Center)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (_isLoadingAddress)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.location_on,
                          color: Colors.indigo,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Koordinat
                  if (_selectedLocation != null)
                    Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                      'Lon: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
