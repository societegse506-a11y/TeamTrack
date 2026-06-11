import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../../../shared/notifiers/settings_notifier.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_colors.dart';
import '../../auth/services/location_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  WorkSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final s = await _service.load();
      if (!mounted) return;
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_settings == null) return;

    // Validation
    if (_settings!.workingDays.isEmpty) {
      _showError('At least one working day must be selected');
      return;
    }
    if (_settings!.lateToleranceMinutes < 0) {
      _showError('Late tolerance cannot be negative');
      return;
    }
    if (_settings!.gpsRadius < 1) {
      _showError('GPS radius must be at least 1 meter');
      return;
    }
    if (_compareTime(_settings!.morningStart, _settings!.morningEnd) >= 0) {
      _showError('Morning start must be before morning end');
      return;
    }
    if (_compareTime(_settings!.afternoonStart, _settings!.afternoonEnd) >= 0) {
      _showError('Afternoon start must be before afternoon end');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.save(_settings!);
      await SettingsNotifier.instance.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int _compareTime(String a, String b) {
    final pa = a.split(':');
    final pb = b.split(':');
    final ha = int.tryParse(pa[0]) ?? 0;
    final ma = int.tryParse(pa[1]) ?? 0;
    final hb = int.tryParse(pb[0]) ?? 0;
    final mb = int.tryParse(pb[1]) ?? 0;
    if (ha != hb) return ha.compareTo(hb);
    return ma.compareTo(mb);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _editWorkplaceLocation() async {
    if (_settings == null) return;
    final loc = _settings!.workplaceLocation;
    final latController = TextEditingController(
      text: loc.lat?.toStringAsFixed(6) ?? '',
    );
    final lngController = TextEditingController(
      text: loc.lng?.toStringAsFixed(6) ?? '',
    );

    double? newLat;
    double? newLng;
    final outerContext = context;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Workplace Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final pos = await LocationService().getCurrentLocation();
                      latController.text = pos.latitude.toStringAsFixed(6);
                      lngController.text = pos.longitude.toStringAsFixed(6);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed to get location: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              if (lat == null || lng == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Invalid coordinates')),
                );
                return;
              }
              newLat = lat;
              newLng = lng;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && newLat != null && newLng != null) {
      setState(() {
        _settings = _settings!.copyWith(
          workplaceLocation: WorkplaceLocation(lat: newLat, lng: newLng),
        );
      });
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(
          content: Text('Workplace location updated. Save settings to persist.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickTime(String current, ValueChanged<String> onPicked) async {
    final parts = current.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 8;
    final initialMinute = int.tryParse(parts[1]) ?? 0;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      onPicked(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Work Rules'),
          actions: [
            TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
        body: _buildBody(isWide),
      );
    });
  }

  Widget _buildBody(bool isWide) {
    final hp = isWide ? 64.0 : 16.0;
    final maxWidth = isWide ? 600.0 : double.infinity;

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: maxWidth,
          child: ListView(
            padding: EdgeInsets.all(hp),
            children: const [
              ShimmerCard(height: 200),
              SizedBox(height: 16),
              ShimmerCard(height: 200),
              SizedBox(height: 16),
              ShimmerCard(height: 160),
            ],
          ),
        ),
      );
    }

    if (_error != null && _settings == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Failed to load settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: maxWidth,
        child: ListView(
          padding: EdgeInsets.fromLTRB(hp, 8, hp, 32),
          children: [
            _buildWorkingHoursCard(),
            const SizedBox(height: 16),
            _buildWorkingDaysCard(),
            const SizedBox(height: 16),
            _buildWorkplaceLocationCard(),
            const SizedBox(height: 16),
            _buildAttendanceRulesCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Settings',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursCard() {
    final theme = Theme.of(context);
    if (_settings == null) return const SizedBox();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientWarning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      size: 20, color: AppColors.warning),
                ),
                const SizedBox(width: 10),
                Text(
                  'Working Hours',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TimeRow(
              label: 'Morning Start',
              value: _settings!.morningStart,
              icon: Icons.wb_sunny,
              iconColor: AppColors.warning,
              onTap: () => _pickTime(
                _settings!.morningStart,
                (v) => setState(() => _settings = _settings!.copyWith(morningStart: v)),
              ),
            ),
            const SizedBox(height: 12),
            _TimeRow(
              label: 'Morning End',
              value: _settings!.morningEnd,
              icon: Icons.wb_cloudy,
              iconColor: Colors.orange.shade300,
              onTap: () => _pickTime(
                _settings!.morningEnd,
                (v) => setState(() => _settings = _settings!.copyWith(morningEnd: v)),
              ),
            ),
            const Divider(height: 28),
            _TimeRow(
              label: 'Afternoon Start',
              value: _settings!.afternoonStart,
              icon: Icons.nights_stay,
              iconColor: AppColors.secondary,
              onTap: () => _pickTime(
                _settings!.afternoonStart,
                (v) => setState(() => _settings = _settings!.copyWith(afternoonStart: v)),
              ),
            ),
            const SizedBox(height: 12),
            _TimeRow(
              label: 'Afternoon End',
              value: _settings!.afternoonEnd,
              icon: Icons.nightlight_round,
              iconColor: Colors.indigo.shade300,
              onTap: () => _pickTime(
                _settings!.afternoonEnd,
                (v) => setState(() => _settings = _settings!.copyWith(afternoonEnd: v)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingDaysCard() {
    final theme = Theme.of(context);
    if (_settings == null) return const SizedBox();

    const allDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday',
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientInfo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_view_week_rounded,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Working Days',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...allDays.map((day) {
              final isSelected = _settings!.workingDays.contains(day);
              final shortDay = day.substring(0, 3).toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: SwitchListTile(
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withAlpha(15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          shortDay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    title: Text(day),
                    value: isSelected,
                    onChanged: (val) {
                      final updated = List<String>.from(_settings!.workingDays);
                      if (val) {
                        updated.add(day);
                      } else {
                        updated.remove(day);
                      }
                      setState(() => _settings = _settings!.copyWith(workingDays: updated));
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkplaceLocationCard() {
    final theme = Theme.of(context);
    if (_settings == null) return const SizedBox();

    final loc = _settings!.workplaceLocation;
    final hasLocation = loc.isSet;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientSuccess.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      size: 20, color: AppColors.success),
                ),
                const SizedBox(width: 10),
                Text(
                  'Workplace Location',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _editWorkplaceLocation,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasLocation) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(loc.lat!, loc.lng!),
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
                            point: LatLng(loc.lat!, loc.lng!),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.business, color: AppColors.primary, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${loc.lat!.toStringAsFixed(6)}, ${loc.lng!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy coordinates',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${loc.lat},${loc.lng}',
                      ));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Coordinates copied'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, size: 18),
                    tooltip: 'Open in Google Maps',
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://www.google.com/maps?q=${loc.lat},${loc.lng}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No workplace location set. It is captured automatically from your registration GPS coordinates.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Click Edit to change the workplace location used for GPS check-in validation.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRulesCard() {
    final theme = Theme.of(context);
    if (_settings == null) return const SizedBox();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientError.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rule_rounded,
                      size: 20, color: AppColors.error),
                ),
                const SizedBox(width: 10),
                Text(
                  'Attendance Rules',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NumberField(
              label: 'Late Tolerance (minutes)',
              value: _settings!.lateToleranceMinutes,
              icon: Icons.access_time,
              iconColor: AppColors.warning,
              helperText: 'Minutes after start time before marked late',
              onChanged: (v) =>
                  setState(() => _settings = _settings!.copyWith(lateToleranceMinutes: v)),
            ),
            const SizedBox(height: 16),
            _NumberField(
              label: 'GPS Radius (meters)',
              value: _settings!.gpsRadius,
              icon: Icons.gps_fixed,
              iconColor: AppColors.primary,
              helperText: 'Allowed check-in zone radius',
              onChanged: (v) => setState(() => _settings = _settings!.copyWith(gpsRadius: v)),
            ),
            const SizedBox(height: 16),
            _TimezonePicker(
              value: _settings!.timezone,
              onChanged: (v) => setState(() => _settings = _settings!.copyWith(timezone: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_calendar, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;
  final String helperText;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.helperText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                helperText,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }
}

const _timezones = [
  'Africa/Tunis',
  'Africa/Cairo',
  'Africa/Casablanca',
  'Africa/Johannesburg',
  'Africa/Lagos',
  'Africa/Nairobi',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Sao_Paulo',
  'America/Mexico_City',
  'America/Toronto',
  'America/Vancouver',
  'Asia/Dubai',
  'Asia/Riyadh',
  'Asia/Kolkata',
  'Asia/Bangkok',
  'Asia/Singapore',
  'Asia/Hong_Kong',
  'Asia/Shanghai',
  'Asia/Tokyo',
  'Asia/Seoul',
  'Asia/Jakarta',
  'Asia/Karachi',
  'Asia/Tehran',
  'Asia/Baghdad',
  'Australia/Sydney',
  'Australia/Melbourne',
  'Australia/Perth',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Madrid',
  'Europe/Rome',
  'Europe/Moscow',
  'Europe/Istanbul',
  'Europe/Amsterdam',
  'Europe/Brussels',
  'Europe/Stockholm',
  'Europe/Oslo',
  'Europe/Zurich',
  'Europe/Vienna',
  'Europe/Warsaw',
  'Europe/Athens',
  'Europe/Lisbon',
  'Europe/Dublin',
  'Pacific/Auckland',
  'Pacific/Fiji',
  'Pacific/Honolulu',
  'UTC',
];

class _TimezonePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TimezonePicker({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timezone',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timezones.contains(value) ? value : _findClosest(value),
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz,
                        child: Text(tz, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _findClosest(String tz) {
    if (_timezones.contains(tz)) return tz;
    final region = tz.split('/').first;
    final match = _timezones.where((t) => t.startsWith('$region/')).toList();
    if (match.isNotEmpty) return match.first;
    return 'UTC';
  }
}
