import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> fetchCurrentWeather() async {
    double lat = 21.60; // Default (Amreli)
    double lon = 71.22;

    try {
      final position = await getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
      }

      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&daily=precipitation_probability_max&timezone=auto');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String getWeatherIcon(int code) {
    // WMO Weather interpretation codes (https://open-meteo.com/en/docs)
    if (code == 0) return '☀️'; // Clear sky
    if (code >= 1 && code <= 3) return 'Vk️'; // Partly cloudy
    if (code >= 45 && code <= 48) return '🌫️'; // Fog
    if (code >= 51 && code <= 67) return '🌧️'; // Drizzle / Rain
    if (code >= 71 && code <= 77) return '❄️'; // Snow
    if (code >= 80 && code <= 82) return '🌧️'; // Showers
    if (code >= 95 && code <= 99) return '⛈️'; // Thunderstorm
    return '❓';
  }
}
