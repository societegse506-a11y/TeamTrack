class WorkplaceLocation {
  final double? lat;
  final double? lng;

  WorkplaceLocation({this.lat, this.lng});

  factory WorkplaceLocation.fromJson(Map<String, dynamic> json) {
    return WorkplaceLocation(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  bool get isSet => lat != null && lng != null;
}

class WorkSettings {
  final String morningStart;
  final String morningEnd;
  final String afternoonStart;
  final String afternoonEnd;
  final int lateToleranceMinutes;
  final int gpsRadius;
  final List<String> workingDays;
  final WorkplaceLocation workplaceLocation;
  final String timezone;

  WorkSettings({
    required this.morningStart,
    required this.morningEnd,
    required this.afternoonStart,
    required this.afternoonEnd,
    required this.lateToleranceMinutes,
    required this.gpsRadius,
    required this.workingDays,
    WorkplaceLocation? workplaceLocation,
    this.timezone = 'UTC',
  }) : workplaceLocation = workplaceLocation ?? WorkplaceLocation();

  factory WorkSettings.fromJson(Map<String, dynamic> json) {
    return WorkSettings(
      morningStart: json['morningStart'] ?? '08:00',
      morningEnd: json['morningEnd'] ?? '12:00',
      afternoonStart: json['afternoonStart'] ?? '14:00',
      afternoonEnd: json['afternoonEnd'] ?? '18:00',
      lateToleranceMinutes: (json['lateToleranceMinutes'] as num?)?.toInt() ?? 15,
      gpsRadius: (json['gpsRadius'] as num?)?.toInt() ?? 500,
      workingDays: (json['workingDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      workplaceLocation: json['workplaceLocation'] != null
          ? WorkplaceLocation.fromJson(json['workplaceLocation'] as Map<String, dynamic>)
          : null,
      timezone: json['timezone'] ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() => {
        'morningStart': morningStart,
        'morningEnd': morningEnd,
        'afternoonStart': afternoonStart,
        'afternoonEnd': afternoonEnd,
        'lateToleranceMinutes': lateToleranceMinutes,
        'gpsRadius': gpsRadius,
        'workingDays': workingDays,
        'timezone': timezone,
        'workplaceLocation': workplaceLocation.toJson(),
      };

  WorkSettings copyWith({
    String? morningStart,
    String? morningEnd,
    String? afternoonStart,
    String? afternoonEnd,
    int? lateToleranceMinutes,
    int? gpsRadius,
    List<String>? workingDays,
    WorkplaceLocation? workplaceLocation,
    String? timezone,
  }) =>
      WorkSettings(
        morningStart: morningStart ?? this.morningStart,
        morningEnd: morningEnd ?? this.morningEnd,
        afternoonStart: afternoonStart ?? this.afternoonStart,
        afternoonEnd: afternoonEnd ?? this.afternoonEnd,
        lateToleranceMinutes: lateToleranceMinutes ?? this.lateToleranceMinutes,
        gpsRadius: gpsRadius ?? this.gpsRadius,
        workingDays: workingDays ?? this.workingDays,
        workplaceLocation: workplaceLocation ?? this.workplaceLocation,
        timezone: timezone ?? this.timezone,
      );
}
