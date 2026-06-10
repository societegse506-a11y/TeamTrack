import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Les services de localisation sont désactivés');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Permission de localisation refusée');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permission de localisation refusée définitivement. Veuillez activer la localisation dans les paramètres.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
