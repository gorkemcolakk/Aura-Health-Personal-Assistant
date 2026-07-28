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
  
  static const _overpassUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  // Türkçe arama terimleri
  static const _queries = {
    'Hastane': 'hastane',
    'Eczane': 'eczane',
    'Klinik': 'klinik',
    'Sağlık Ocağı': 'sağlık ocağı',
    'Diş Hekimi': 'diş hekimi',
    'Veteriner': 'veteriner',
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
          'User-Agent': 'AuraHealthApp/1.0 (contact@aurahealth.app)',
          'Accept-Language': 'tr',
        },
      ).timeout(const Duration(seconds: 15));

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
    'Sağlık Ocağı': ['"healthcare"="centre"'],
    'Diş Hekimi': ['"amenity"="dentist"'],
    'Veteriner': ['"amenity"="veterinary"'],
  };

  String? lastDebugError;

  Future<List<HealthFacility>> findNearbyHealthFacilities({
    required double lat,
    required double lng,
    int maxDistanceKm = 3,
  }) async {
    lastDebugError = null;
    
    // 1. Try Overpass API with multiple fallbacks
    for (final url in _overpassUrls) {
      try {
        final overpassResults = await _searchOverpass(url, lat, lng, maxDistanceKm);
        if (overpassResults.isNotEmpty) return overpassResults;
      } catch (_) {
        // Fallback to the next URL
      }
    }

    // 2. If all Overpass servers fail, use Nominatim as absolute fallback
    try {
      return await _searchNominatim(lat, lng, maxDistanceKm);
    } catch (_) {
      return [];
    }
  }

  Future<List<HealthFacility>> _searchOverpass(
    String overpassUrl, double lat, double lng, int maxDistanceKm,
  ) async {
    final allResults = <HealthFacility>[];

    // Combine all tag queries into a single Overpass QL block using nwr
    final tagQueries = StringBuffer();
    for (final entry in _osmTags.entries) {
      for (final t in entry.value) {
        tagQueries.write('nwr[$t](around:${maxDistanceKm * 1000},$lat,$lng);');
      }
    }
    
    final query = '[out:json];(${tagQueries.toString()});out center;';

    final response = await http.post(
      Uri.parse(overpassUrl),
      body: query,
      headers: {
        'Content-Type': 'text/plain',
        'User-Agent': 'AuraHealthApp/1.0 (contact@aurahealth.app)',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List<dynamic>?;

      if (elements != null) {
        for (final el in elements) {
          final tags = el['tags'] as Map<String, dynamic>?;
          if (tags == null) continue;

          // For 'nwr' with 'out center', nodes have lat/lon directly, 
          // ways/relations have center properties
          final center = el['center'];
          final rLat = (el['lat'] ?? center?['lat'] as num?)?.toDouble() ?? 0.0;
          final rLng = (el['lon'] ?? center?['lon'] as num?)?.toDouble() ?? 0.0;
          
          if (rLat == 0.0 || rLng == 0.0) continue;

          final dist = _haversineKm(lat, lng, rLat, rLng);
          if (dist > maxDistanceKm) continue;

          // Determine base type by checking tags against _osmTags
          String baseType = 'Sağlık Kuruluşu';
          for (final entry in _osmTags.entries) {
            bool matched = false;
            for (final t in entry.value) {
              final parts = t.replaceAll('"', '').split('=');
              if (parts.length == 2 && tags[parts[0]] == parts[1]) {
                matched = true;
                break;
              }
            }
            if (matched) {
              baseType = entry.key;
              break;
            }
          }

          String rawName = tags['name']?.toString() ??
              tags['name:tr']?.toString() ??
              baseType;
              
          final type = _postProcessType(rawName, baseType);
          
          if (rawName != type && rawName != 'Sağlık Kuruluşu') {
            final lowerName = rawName.toLowerCase();
            if (type == 'Eczane' && !lowerName.contains('eczane')) {
              rawName = '$rawName Eczanesi';
            } else if (type == 'Diş Hekimi' && !lowerName.contains('diş') && !lowerName.contains('dentist')) {
              rawName = '$rawName Diş Hekimi';
            } else if (type == 'Veteriner' && !lowerName.contains('veteriner') && !lowerName.contains('vet')) {
              rawName = '$rawName Veteriner Kliniği';
            } else if (type == 'Klinik' && !lowerName.contains('klinik') && !lowerName.contains('poliklinik') && !lowerName.contains('clinic')) {
              rawName = '$rawName Kliniği';
            } else if (type == 'Hastane' && !lowerName.contains('hastane') && !lowerName.contains('hospital') && !lowerName.contains('tıp')) {
              rawName = '$rawName Hastanesi';
            }
          }
          
          final street = tags['addr:street']?.toString() ?? '';
          final housenumber = tags['addr:housenumber']?.toString() ?? '';
          final suburb = tags['addr:suburb']?.toString() ?? '';
          final district = tags['addr:district']?.toString() ?? '';
          final city = tags['addr:city']?.toString() ?? '';

          String streetWithNumber = street;
          if (street.isNotEmpty && housenumber.isNotEmpty) {
            streetWithNumber = '$street No:$housenumber';
          }

          final addressParts = <String>[];
          if (streetWithNumber.isNotEmpty) addressParts.add(streetWithNumber);
          if (suburb.isNotEmpty) addressParts.add(suburb);
          if (district.isNotEmpty) addressParts.add(district);
          if (city.isNotEmpty) addressParts.add(city);

          final address = addressParts.isEmpty 
              ? 'Adres detayı haritada bulunmuyor.' 
              : '$rawName, ${addressParts.join(', ')}';

          allResults.add(HealthFacility(
            name: rawName,
            address: address,
            type: type,
            lat: rLat,
            lng: rLng,
            distanceKm: dist,
          ));
        }
      }
    } else {
      throw Exception('Overpass returned non-200');
    }

    return _filterAndSort(allResults, lat, lng);
  }

  Future<List<HealthFacility>> _searchNominatim(
    double lat, double lng, int maxDistanceKm,
  ) async {
    final allResults = <HealthFacility>[];
    final delta = maxDistanceKm / 111.0;

    for (final entry in _queries.entries) {
      try {
        final url = Uri.parse(
          '$_nominatimUrl/search'
          '?q=${Uri.encodeComponent(entry.value)}'
          '&format=json'
          '&limit=10'
          '&bounded=1'
          '&viewbox=${lng - delta},${lat + delta},${lng + delta},${lat - delta}',
        );

        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'AuraHealthApp/1.0 (contact@aurahealth.app)',
            'Accept-Language': 'tr',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final results = jsonDecode(response.body) as List<dynamic>;

          for (final r in results) {
            final rLat = double.tryParse(r['lat']?.toString() ?? '0') ?? 0;
            final rLng = double.tryParse(r['lon']?.toString() ?? '0') ?? 0;

            final dist = _haversineKm(lat, lng, rLat, rLng);
            if (dist > maxDistanceKm) continue;

            final rawName = r['display_name']?.toString().split(',').first.trim() ?? 'Bilinmiyor';
            final type = _postProcessType(rawName, entry.key);

            allResults.add(HealthFacility(
              name: rawName,
              address: r['display_name']?.toString() ?? '',
              type: type,
              lat: rLat,
              lng: rLng,
              distanceKm: dist,
            ));
          }
        }
      } catch (_) {}
      
      await Future.delayed(const Duration(seconds: 1));
    }

    return _filterAndSort(allResults, lat, lng);
  }

  /// Akıllı Kategori Ayrıştırması (İsme Göre Düzeltme)
  String _postProcessType(String name, String baseType) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('sağlık ocağı') || 
        lowerName.contains('aile sağlığı') || 
        lowerName.contains('asm')) {
      return 'Sağlık Ocağı';
    }
    if (lowerName.contains('hastane') || 
        lowerName.contains('hospital') ||
        lowerName.contains('tıp merkezi') ||
        lowerName.contains('poliklinik')) {
      return 'Hastane';
    }
    if (lowerName.contains('eczane') || lowerName.contains('pharmacy')) {
      return 'Eczane';
    }
    if (lowerName.contains('diş') || lowerName.contains('dentist')) {
      return 'Diş Hekimi';
    }
    if (lowerName.contains('veteriner') || lowerName.contains('vet')) {
      return 'Veteriner';
    }
    return baseType;
  }

  List<HealthFacility> _filterAndSort(List<HealthFacility> results, double lat, double lng) {
    final seen = <String>{};
    final filtered = results.where((f) {
      final key = '${f.name}_${f.lat}_${f.lng}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    filtered.sort((a, b) {
      final dA = a.distanceKm ?? 0.0;
      final dB = b.distanceKm ?? 0.0;
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
