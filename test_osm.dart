import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  double lat = 41.0082;
  double lng = 28.9784;
  int maxDistanceKm = 3;

  print('Searching Overpass via GET...');
  final tagQueries = 'node["amenity"="hospital"](around:${maxDistanceKm * 1000},$lat,$lng);';
  final query = '[out:json];($tagQueries);out body 30;';

  final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}');
  print(url);
  try {
    final response = await http.get(url, headers: {'User-Agent': 'AuraHealthApp/1.0'});
    print('Overpass status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List<dynamic>?;
      print('Found ${elements?.length} nodes via Overpass');
    } else {
      print(response.body);
    }
  } catch (e) {
    print('Overpass error: $e');
  }
}
