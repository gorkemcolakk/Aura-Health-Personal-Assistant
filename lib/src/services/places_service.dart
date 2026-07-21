import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class HealthFacility {
  final String name;
  final String address;
  final String type;
  final double lat;
  final double lng;
  final double? rating;
  final bool openNow;
  final double? distanceKm;

  const HealthFacility({
    required this.name,
    required this.address,
    required this.type,
    required this.lat,
    required this.lng,
    this.rating,
    this.openNow = false,
    this.distanceKm,
  });
}

class PlacesService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // Türkçe arama terimleri + OSM tag'leri
  static const _queries = {
    'Hastane': 'hospital',
    'Eczane': 'eczane',
    'Klinik': 'clinic',
    'Sağlık Ocağı': 'aile sağlığı merkezi',
  };

  /// Adresi koordinata çevir
  Future<(double, double)?> geocode(String address) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl/search'
        '?q=${Uri.encodeComponent(address)}'
        '&format=json'
        '&limit=1',
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
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat']?.toString() ?? '');
          final lng = double.tryParse(results[0]['lon']?.toString() ?? '');
          if (lat != null && lng != null) return (lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  // Overpass API OSM tag eşleştirmesi
  static const _osmTags = {
    'Hastane': ['"amenity"="hospital"'],
    'Eczane': ['"amenity"="pharmacy"', '"shop"="chemist"'],
    'Klinik': ['"amenity"="clinic"', '"amenity"="doctors"'],
    'Sağlık Ocağı': ['"amenity"="clinic"', '"healthcare"="centre"'],
  };

  Future<List<HealthFacility>> findNearbyHealthFacilities({
    required double lat,
    required double lng,
    int maxDistanceKm = 3,
  }) async {
    // Önce Overpass API dene (daha iyi sonuç)
    final overpassResults = await _searchOverpass(lat, lng, maxDistanceKm);
    if (overpassResults.isNotEmpty) return overpassResults;

    // Fallback: Nominatim
    return _searchNominatim(lat, lng, maxDistanceKm);
  }

  Future<List<HealthFacility>> _searchOverpass(
    double lat, double lng, int maxDistanceKm,
  ) async {
    final allResults = <HealthFacility>[];

    for (final entry in _osmTags.entries) {
      final tagQueries = entry.value.map((t) => 'node[$t](around:${maxDistanceKm * 1000},$lat,$lng);').join();
      final query = '[out:json];($tagQueries);out body 30;';

      try {
        final response = await http.post(
          Uri.parse(_overpassUrl),
          body: query,
          headers: {'Content-Type': 'text/plain'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final elements = data['elements'] as List<dynamic>?;

          if (elements != null) {
            for (final el in elements) {
              final tags = el['tags'] as Map<String, dynamic>?;
              if (tags == null) continue;

              final rLat = (el['lat'] as num?)?.toDouble() ?? 0.0;
              final rLng = (el['lon'] as num?)?.toDouble() ?? 0.0;
              final dist = _haversineKm(lat, lng, rLat, rLng);
              if (dist > maxDistanceKm) continue;

              final name = tags['name']?.toString() ??
                  tags['name:tr']?.toString() ??
                  entry.key;
              final street = tags['addr:street']?.toString() ?? '';
              final city = tags['addr:city']?.toString() ?? '';

              allResults.add(HealthFacility(
                name: name,
                address: '$name, $street, $city'.trim(),
                type: entry.key,
                lat: rLat,
                lng: rLng,
                distanceKm: dist,
              ));
            }
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Duplicate temizle, mesafeye göre sırala
    final seen = <String>{};
    final filtered = allResults.where((f) {
      final key = '${f.name}_${f.lat}_${f.lng}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    filtered.sort((a, b) {
      final dA = _haversineKm(lat, lng, a.lat, a.lng);
      final dB = _haversineKm(lat, lng, b.lat, b.lng);
      return dA.compareTo(dB);
    });

    return filtered;
  }

  Future<List<HealthFacility>> _searchNominatim(
    double lat, double lng, int maxDistanceKm,
  ) async {
    final allResults = <HealthFacility>[];

    // 5km için yaklaşık 0.05 derece
    final delta = maxDistanceKm / 111.0;

    for (final entry in _queries.entries) {
      try {
        final url = Uri.parse(
          '$_nominatimUrl/search'
          '?q=${Uri.encodeComponent(entry.value)}'
          '&format=json'
          '&limit=20'
          '&bounded=1'
          '&viewbox=${lng - delta},${lat - delta},${lng + delta},${lat + delta}',
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
            final rLat = double.tryParse(r['lat']?.toString() ?? '0') ?? 0;
            final rLng = double.tryParse(r['lon']?.toString() ?? '0') ?? 0;

            // Kesin mesafe filtresi (Haversine)
            final dist = _haversineKm(lat, lng, rLat, rLng);
            if (dist > maxDistanceKm) continue;

            allResults.add(HealthFacility(
              name: r['display_name']?.toString().split(',').first.trim() ?? 'Bilinmiyor',
              address: r['display_name']?.toString() ?? '',
              type: entry.key,
              lat: rLat,
              lng: rLng,
              distanceKm: dist,
            ));
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 1));
    }

    // Duplicate temizle ve mesafeye göre sırala
    final seen = <String>{};
    final filtered = allResults.where((f) {
      final key = '${f.name}_${f.lat}_${f.lng}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    filtered.sort((a, b) {
      final dA = _haversineKm(lat, lng, a.lat, a.lng);
      final dB = _haversineKm(lat, lng, b.lat, b.lng);
      return dA.compareTo(dB);
    });

    return filtered;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * pi / 180;
}
