import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  static String formatCoordinates(Position position) {
    return 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
  }
}