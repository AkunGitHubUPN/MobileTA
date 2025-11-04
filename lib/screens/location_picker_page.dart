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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        backgroundColor: const Color(0xFFFF6B4A),
        foregroundColor: Colors.white,
        elevation: 0,
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
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Color(0xFFFF6B4A),
                            size: 45,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // KONTROL ZOOM (Kanan Bawah)
          Positioned(
            right: 16,
            bottom: 200,
            child: Row(
              children: [
                // Tombol Zoom Out
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out_location',
                  backgroundColor: const Color(0xFFFF6B4A),
                  foregroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                // Tombol Zoom In
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in_location',
                  backgroundColor: const Color(0xFFFF6B4A),
                  foregroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
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
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header dengan icon lokasi
                  Row(
                    children: [
                      if (_isLoadingAddress)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFFFF6B4A),
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF6B4A),
                          size: 24,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Pilihan',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Divider
                  Divider(
                    color: Colors.grey[300],
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  // Koordinat
                  if (_selectedLocation != null)
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                            'Lon: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Klik di peta untuk memilih lokasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // Tombol Tetapkan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Tetapkan Lokasi Ini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B4A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _selectedLocation != null
                          ? _confirmLocation
                          : null,
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
