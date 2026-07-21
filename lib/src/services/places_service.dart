import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/secrets.dart';

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
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static const _healthTypes = [
    'hospital',
    'pharmacy',
    'doctor',
    'health',
  ];

  Future<List<HealthFacility>> findNearbyHealthFacilities({
    required double lat,
    required double lng,
    int radius = 5000,
  }) async {
    final allResults = <HealthFacility>[];

    for (final type in _healthTypes) {
      try {
        final url = Uri.parse(
          '$_baseUrl/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=$radius'
          '&type=$type'
          '&key=$googleMapsApiKey',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] as List<dynamic>?;

          if (results != null) {
            for (final r in results) {
              final types = List<String>.from(r['types'] ?? []);
              String facilityType;
              if (types.contains('hospital')) {
                facilityType = 'Hastane';
              } else if (types.contains('pharmacy')) {
                facilityType = 'Eczane';
              } else if (types.contains('doctor')) {
                facilityType = 'Klinik';
              } else {
                facilityType = 'Sağlık';
              }

              allResults.add(HealthFacility(
                name: r['name']?.toString() ?? 'Bilinmiyor',
                address: r['vicinity']?.toString() ?? '',
                type: facilityType,
                lat: (r['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0,
                lng: (r['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0,
                rating: (r['rating'] as num?)?.toDouble(),
                openNow: r['opening_hours']?['open_now'] == true,
              ));
            }
          }
        }
      } catch (_) {
        // Bir tipte hata olsa da diğerlerini dene
      }
    }

    // Duplicate'ları temizle (aynı yere birden fazla tipte denk gelmiş olabilir)
    final seen = <String>{};
    return allResults.where((f) {
      final key = '${f.name}_${f.lat}_${f.lng}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}
