import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool success;
  final String message;
  final Position? position;
  const LocationResult(this.success, this.message, [this.position]);
}

/// Gets the device's current GPS position, handling the full permission dance.
class LocationService {
  static Future<LocationResult> getCurrentPosition() async {
    // 1. Location services enabled on the device?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
          false, "Geolokatsiya o'chirilgan. Iltimos, uni yoqing.");
    }

    // 2. Permission granted?
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
            false, "Joylashuvga ruxsat berilmadi.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
          false,
          "Joylashuvga ruxsat butunlay rad etilgan. Sozlamalardan yoqing.");
    }

    // 3. Read position
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      return LocationResult(true, "OK", pos);
    } catch (e) {
      return LocationResult(false, "Joylashuvni aniqlab bo'lmadi: $e");
    }
  }
}
