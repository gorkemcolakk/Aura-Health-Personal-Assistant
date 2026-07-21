import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/secrets.dart';
import '../services/places_service.dart';
import '../widgets/aura_card.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  GoogleMapController? _mapController;
  final _placesService = PlacesService();

  LatLng? _currentLocation;
  List<HealthFacility> _facilities = [];
  bool _loading = true;
  String? _error;

  // İstanbul varsayılan konum
  static const _defaultLocation = LatLng(41.0082, 28.9784);

  final Map<String, BitmapDescriptor> _markerIcons = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _initLocation();
  }

  Future<void> _loadMarkers() async {
    _markerIcons['Hastane'] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
    _markerIcons['Eczane'] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    _markerIcons['Klinik'] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
    _markerIcons['Sağlık'] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueOrange,
    );
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission = await _handlePermission();
      if (!hasPermission) {
        setState(() {
          _loading = false;
          _error = 'Konum izni gerekli';
        });
        await _searchNearby(_defaultLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(position.latitude, position.longitude);
      setState(() => _currentLocation = location);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 14));
      await _searchNearby(location);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Konum alınamadı: $e';
      });
      await _searchNearby(_defaultLocation);
    }
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
        radius: 10000,
      );

      setState(() {
        _facilities = facilities;
        _loading = false;
      });

      if (_mapController != null && facilities.isNotEmpty) {
        final bounds = _computeBounds(location, facilities);
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }
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

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'Konumunuz'),
        ),
      );
    }

    for (final f in _facilities) {
      markers.add(
        Marker(
          markerId: MarkerId('${f.name}_${f.lat}_${f.lng}'),
          position: LatLng(f.lat, f.lng),
          icon: _markerIcons[f.type] ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: f.name,
            snippet: '${f.type} ${f.rating != null ? "⭐${f.rating}" : ""}',
          ),
        ),
      );
    }

    return markers;
  }

  void _openDirections(HealthFacility facility) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${facility.lat},${facility.lng}';
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: colors.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Yakın Sağlık Kuruluşları',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (!_loading)
                  IconButton(
                    onPressed: () => _initLocation(),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Yenile',
                  ),
              ],
            ),
          ),

          // Harita
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? _defaultLocation,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _buildMarkers(),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Center(
                      child: AuraCard(
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  // Lejant
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alt liste
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
                            onTap: () => _openDirections(facility),
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
                                        Text(
                                          facility.name,
                                          style: Theme.of(context).textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          facility.address,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (facility.rating != null) ...[
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 2),
                                    Text(facility.rating!.toStringAsFixed(1)),
                                  ],
                                  const SizedBox(width: 8),
                                  const Icon(Icons.directions, size: 20),
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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
