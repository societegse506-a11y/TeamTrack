import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../features/auth/services/location_service.dart';
import '../../theme/app_colors.dart';

class WorkplaceMap extends StatelessWidget {
  final double workplaceLat;
  final double workplaceLng;
  final double currentLat;
  final double currentLng;
  final String label;
  final bool showCurrentLocation;
  final bool showGpsButton;

  const WorkplaceMap({
    super.key,
    required this.workplaceLat,
    required this.workplaceLng,
    this.currentLat = 0.0,
    this.currentLng = 0.0,
    this.label = 'Workplace Location',
    this.showCurrentLocation = true,
    this.showGpsButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (workplaceLat == 0.0 && workplaceLng == 0.0) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Location not available',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('Register with GPS to set your workplace location.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final workplace = LatLng(workplaceLat, workplaceLng);
    final markers = <Marker>[
      Marker(
        point: workplace,
        width: 40,
        height: 40,
        child: const Icon(Icons.business, color: AppColors.primary, size: 32),
      ),
    ];

    if (showCurrentLocation && currentLat != 0.0 && currentLng != 0.0) {
      markers.add(
        Marker(
          point: LatLng(currentLat, currentLng),
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: AppColors.success, size: 32),
        ),
      );
      final distance = _calculateDistance(workplaceLat, workplaceLng, currentLat, currentLng);
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(label,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: distance < 100 ? AppColors.success.withAlpha(20) : AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      distance < 1000 ? '${distance.toInt()}m away' : '${(distance / 1000).toStringAsFixed(1)}km away',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: distance < 100 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: workplace,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.teamtrack.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: workplace,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.teamtrack.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * (3.141592653589793 / 180);
  double _sin(double x) => x - (x * x * x / 6) + (x * x * x * x * x / 120);
  double _cos(double x) => 1 - (x * x / 2) + (x * x * x * x / 24);
  double _sqrt(double x) => x < 0 ? 0 : x > 1 ? 1 : x;
  double _atan2(double y, double x) => math.atan2(y, x);
}

class LocationMapWidget extends StatefulWidget {
  final double workplaceLat;
  final double workplaceLng;

  const LocationMapWidget({
    super.key,
    required this.workplaceLat,
    required this.workplaceLng,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  double _currentLat = 0.0;
  double _currentLng = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return WorkplaceMap(
      workplaceLat: widget.workplaceLat,
      workplaceLng: widget.workplaceLng,
      currentLat: _currentLat,
      currentLng: _currentLng,
    );
  }
}
