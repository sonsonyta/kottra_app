import 'package:geolocator/geolocator.dart';

class LocationCoords {
  const LocationCoords({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract class LocationServiceBase {
  Future<LocationCoords?> getCurrentCoords();
}

class LocationService implements LocationServiceBase {
  const LocationService();

  @override
  Future<LocationCoords?> getCurrentCoords() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationCoords(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
