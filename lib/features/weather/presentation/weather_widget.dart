import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final _service = WeatherService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _service.fetchCurrentWeather();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LinearProgressIndicator());
    if (_error != null) return const SizedBox.shrink(); // Hide on error for cleaner UI

    final current = _data?['current'];
    final daily = _data?['daily'];
    
    if (current == null) return const SizedBox.shrink();

    final temp = current['temperature_2m'];
    final code = current['weather_code'];
    final icon = _service.getWeatherIcon(code);
    final rainChance = daily?['precipitation_probability_max']?[0] ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.localWeather ?? 'Local Weather',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$temp°C',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${AppLocalizations.of(context)?.rainChance ?? "Rain Chance"}: $rainChance%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
          ],
        ),
      ),
    );
  }
}
