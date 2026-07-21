import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/places_service.dart';
import '../widgets/aura_card.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final _placesService = PlacesService();
  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng? _currentLocation;
  List<HealthFacility> _facilities = [];
  bool _loading = true;
  String? _error;

  static const _defaultLocation = LatLng(41.0082, 28.9784);

  static const _typeColors = {
    'Hastane': Colors.red,
    'Eczane': Colors.green,
    'Klinik': Colors.blue,
    'Sağlık Ocağı': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission = await _handlePermission();
      if (!hasPermission || !await Geolocator.isLocationServiceEnabled()) {
        setState(() => _loading = false);
        await _searchNearby(_defaultLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final location = LatLng(position.latitude, position.longitude);

      // Emülatör Mountain View sahte konumunu yakala, İstanbul'a düş
      if (_isEmulatorLocation(location)) {
        setState(() => _currentLocation = _defaultLocation);
        _mapController.move(_defaultLocation, 12);
        await _searchNearby(_defaultLocation);
        return;
      }

      setState(() => _currentLocation = location);
      _mapController.move(location, 14);
      await _searchNearby(location);
    } catch (e) {
      setState(() => _loading = false);
      await _searchNearby(_defaultLocation);
    }
  }

  bool _isEmulatorLocation(LatLng loc) {
    // Google HQ civarı (Mountain View / Palo Alto emülatör varsayılanı)
    const emulatorLat = 37.42;
    const emulatorLng = -122.08;
    const tolerance = 0.5;
    return (loc.latitude - emulatorLat).abs() < tolerance &&
           (loc.longitude - emulatorLng).abs() < tolerance;
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _loading = true);

    final coords = await _placesService.geocode(query.trim());
    if (coords == null) {
      setState(() {
        _loading = false;
        _error = '"$query" bulunamadı';
      });
      return;
    }

    final location = LatLng(coords.$1, coords.$2);
    setState(() {
      _currentLocation = location;
      _error = null;
    });

    _mapController.move(location, 14);
    await _searchNearby(location);
  }

  Future<bool> _handlePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _searchNearby(LatLng location) async {
    try {
      final facilities = await _placesService.findNearbyHealthFacilities(
        lat: location.latitude,
        lng: location.longitude,
      );

      setState(() {
        _facilities = facilities;
        _loading = false;
      });

      // Arama noktasına odaklan, tüm sonuçlara zoom out yapma
      _mapController.move(location, 14);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Sağlık kuruluşları yüklenemedi';
      });
    }
  }

  LatLngBounds _computeBounds(LatLng center, List<HealthFacility> facilities) {
    double minLat = center.latitude;
    double maxLat = center.latitude;
    double minLng = center.longitude;
    double maxLng = center.longitude;

    for (final f in facilities) {
      if (f.lat < minLat) minLat = f.lat;
      if (f.lat > maxLat) maxLat = f.lat;
      if (f.lng < minLng) minLng = f.lng;
      if (f.lng > maxLng) maxLng = f.lng;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 30,
          height: 30,
          child: const Icon(Icons.my_location, color: Colors.purple, size: 30),
        ),
      );
    }

    for (final f in _facilities) {
      final color = _typeColors[f.type] ?? Colors.grey;
      markers.add(
        Marker(
          point: LatLng(f.lat, f.lng),
          width: 60,
          height: 80,
          child: GestureDetector(
            onTap: () => _showFacilityInfo(f),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                  ),
                  child: Text(
                    f.name,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(Icons.location_on, color: color, size: 28),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showFacilityInfo(HealthFacility facility) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_typeIcon(facility.type), style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(facility.name, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(facility.address, style: Theme.of(context).textTheme.bodySmall, maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openDirections(facility);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Haritada Göster'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDirections(HealthFacility facility) async {
    // Sadece konumu göster, rota çizme (emülatör uyumlu)
    final url = 'https://www.google.com/maps/search/?api=1&query=${facility.lat},${facility.lng}';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _typeIcon(String type) {
    switch (type) {
      case 'Hastane':
        return '🏥';
      case 'Eczane':
        return '💊';
      case 'Klinik':
        return '🩺';
      case 'Sağlık Ocağı':
        return '🏚️';
      default:
        return '🏥';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: colors.primary, size: 28),
                const SizedBox(width: 10),
                Text('Yakın Sağlık Kuruluşları', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                if (!_loading)
                  IconButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _initLocation();
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Yenile',
                  ),
              ],
            ),
          ),
          // Konum bilgisi
          if (_currentLocation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                    '${_currentLocation == _defaultLocation ? " (İstanbul)" : ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          // Adres arama
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Adres veya semt ara (örn: Kadıköy)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: () => _searchAddress(_searchController.text),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              style: Theme.of(context).textTheme.bodySmall,
              onSubmitted: _searchAddress,
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ?? _defaultLocation,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.aurahealth.app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                  if (_loading) const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Center(
                      child: AuraCard(
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AuraCard(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(Colors.red, 'Hastane'),
                          _legendItem(Colors.green, 'Eczane'),
                          _legendItem(Colors.blue, 'Klinik'),
                          _legendItem(Colors.orange, 'Sağlık Ocağı'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _facilities.isEmpty && !_loading
                ? Center(
                    child: Text(
                      _error ?? 'Yakında sağlık kuruluşu bulunamadı',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _facilities.length,
                    itemBuilder: (context, index) {
                      final facility = _facilities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AuraCard(
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _mapController.move(LatLng(facility.lat, facility.lng), 16);
                              _showFacilityInfo(facility);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Text(_typeIcon(facility.type), style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(facility.name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(facility.address, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.map, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.8), shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
