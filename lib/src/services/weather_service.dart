import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String condition;
  final int weatherCode;
  
  WeatherData({
    required this.temperature,
    required this.condition,
    required this.weatherCode,
  });
}

class WeatherService {
  static WeatherData? _cachedWeather;
  static DateTime? _lastFetch;

  static Future<WeatherData?> fetchCurrentWeather() async {
    // Return cache if it's less than 1 hour old
    if (_cachedWeather != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inHours < 1) {
        return _cachedWeather;
      }
    }

    try {
      // 1. Get location via IP (no permissions required, HTTPS)
      final ipResponse = await http.get(Uri.parse('https://get.geojs.io/v1/ip/geo.json'));
      if (ipResponse.statusCode != 200) return null;
      
      final ipData = jsonDecode(ipResponse.body);
      final double lat = double.parse(ipData['latitude'].toString());
      final double lon = double.parse(ipData['longitude'].toString());

      // 2. Get weather via Open-Meteo
      final weatherUrl = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true';
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      if (weatherResponse.statusCode != 200) return null;

      final weatherData = jsonDecode(weatherResponse.body);
      final current = weatherData['current_weather'];
      
      final temp = (current['temperature'] as num).toDouble();
      final code = current['weathercode'] as int;
      
      // Simple weather string translation
      String condition = _getConditionFromCode(code);

      _cachedWeather = WeatherData(
        temperature: temp,
        condition: condition,
        weatherCode: code,
      );
      _lastFetch = DateTime.now();

      return _cachedWeather;
    } catch (e) {
      print("Weather fetch error: $e");
      return null;
    }
  }

  static String _getConditionFromCode(int code) {
    if (code == 0) return 'Güneşli / Açık'; // Clear sky
    if (code == 1 || code == 2 || code == 3) return 'Parçalı Bulutlu';
    if (code == 45 || code == 48) return 'Sisli'; // Fog
    if (code >= 51 && code <= 67) return 'Yağmurlu'; // Drizzle / Rain
    if (code >= 71 && code <= 77) return 'Karlı'; // Snow
    if (code >= 80 && code <= 82) return 'Sağanak Yağışlı'; // Rain showers
    if (code >= 95 && code <= 99) return 'Fırtınalı'; // Thunderstorm
    return 'Bilinmiyor';
  }
}
