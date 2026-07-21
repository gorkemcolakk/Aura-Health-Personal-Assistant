import 'dart:convert';

import 'package:http/http.dart' as http;

class HealthFacility {
  final String name;
  final String address;
  final String type;
  final double lat;
  final double lng;
  final double? rating;
  final bool openNow;

  const HealthFacility({
    required this.name,
    required this.address,
    required this.type,
    required this.lat,
    required this.lng,
    this.rating,
    this.openNow = false,
  });
}

class PlacesService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org';

  // Her tip için ayrı arama (Nominatim free-text search)
  static const _queries = {
    'Hastane': 'hospital',
    'Eczane': 'pharmacy',
    'Klinik': 'clinic',
    'Sağlık Ocağı': 'health centre',
  };

  Future<List<HealthFacility>> findNearbyHealthFacilities({
    required double lat,
    required double lng,
    int radius = 10000,
  }) async {
    final allResults = <HealthFacility>[];

    for (final entry in _queries.entries) {
      try {
        final url = Uri.parse(
          '$_nominatimUrl/search'
          '?q=${Uri.encodeComponent(entry.value)}'
          '&format=json'
          '&limit=15'
          '&bounded=1'
          '&viewbox=${lng - 0.15},${lat - 0.15},${lng + 0.15},${lat + 0.15}',
        );

        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'AuraHealthApp/1.0',
            'Accept-Language': 'tr',
          },
        );

        if (response.statusCode == 200) {
          final results = jsonDecode(response.body) as List<dynamic>;

          for (final r in results) {
            allResults.add(HealthFacility(
              name: r['display_name']?.toString().split(',').first.trim() ?? 'Bilinmiyor',
              address: r['display_name']?.toString() ?? '',
              type: entry.key,
              lat: double.tryParse(r['lat']?.toString() ?? '0') ?? 0,
              lng: double.tryParse(r['lon']?.toString() ?? '0') ?? 0,
            ));
          }
        }
      } catch (_) {
        // Bir tipte hata olsa da diğerlerini dene
      }

      // Nominatim rate limit: saniyede 1 istek
      await Future.delayed(const Duration(seconds: 1));
    }

    // Duplicate'ları temizle
    final seen = <String>{};
    return allResults.where((f) {
      final key = '${f.name}_${f.lat}_${f.lng}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}
