import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<String> getAddressFromCoords(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${location.latitude}&lon=${location.longitude}',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'jejak_pena_app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? 'Lokasi tidak dikenal';
      } else {
        return 'Gagal mengambil nama lokasi';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  static Future<String> getAddressFromPosition(Position position) async {
    final latLng = LatLng(position.latitude, position.longitude);
    return getAddressFromCoords(latLng);
  }

  static String formatLocationName(String locationName) {
    if (locationName.isEmpty) {
      return 'Lokasi Tidak Diketahui';
    }

    List<String> parts = locationName.split(',');
    
    if (parts.length >= 3) {
      return "${parts[parts.length - 3].trim()}, ${parts[parts.length - 1].trim()}";
    }
    
    return locationName;
  }
}