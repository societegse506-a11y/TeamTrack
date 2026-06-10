import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../features/auth/services/location_service.dart';
import '../../theme/app_colors.dart';

class WorkplaceLocationMap extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const WorkplaceLocationMap({
    super.key,
    required this.lat,
    required this.lng,
    this.label = 'Workplace Location',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (lat == 0.0 && lng == 0.0) {
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
              Text('Workplace location not set',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('Configure it in Settings.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final point = LatLng(lat, lng);

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
                Icon(Icons.business, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.teamtrack.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.business, color: AppColors.primary, size: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentPositionMap extends StatefulWidget {
  const CurrentPositionMap({super.key});

  @override
  State<CurrentPositionMap> createState() => _CurrentPositionMapState();
}

class _CurrentPositionMapState extends State<CurrentPositionMap> {
  double _lat = 0.0;
  double _lng = 0.0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) setState(() { _lat = position.latitude; _lng = position.longitude; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: const SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || (_lat == 0.0 && _lng == 0.0)) {
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
              Icon(Icons.gps_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Current position unavailable',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final point = LatLng(_lat, _lng);

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
                Icon(Icons.my_location, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text('My Current Position',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.teamtrack.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: AppColors.success, size: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
