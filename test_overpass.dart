import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final lat = 41.0084;
  final lng = 28.9745;
  final maxDistanceKm = 3;

  final _osmTags = {
    'Hastane': ['"amenity"="hospital"'],
    'Eczane': ['"amenity"="pharmacy"', '"shop"="chemist"'],
    'Klinik': ['"amenity"="clinic"', '"amenity"="doctors"'],
    'Sağlık Ocağı': ['"amenity"="clinic"', '"healthcare"="centre"'],
  };

  final tagQueries = StringBuffer();
  for (final entry in _osmTags.entries) {
    for (final t in entry.value) {
      tagQueries.write('nwr[$t](around:${maxDistanceKm * 1000},$lat,$lng);');
    }
  }
  
  final query = '[out:json];(${tagQueries.toString()});out center;';
  print('Executing query: $query');

  try {
    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: query,
      headers: {
        'Content-Type': 'text/plain',
        'User-Agent': 'AuraHealthApp/1.0 (contact@aurahealth.app)',
      },
    );

    print('Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List<dynamic>?;
      print('Elements found: ${elements?.length}');
      if (elements != null && elements.isNotEmpty) {
        print('First element: ${elements.first}');
      }
    } else {
      print('Error body: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
