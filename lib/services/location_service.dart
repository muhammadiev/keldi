import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool ok;
  final String message;
  final Position? position;
  const LocationResult(this.ok, this.message, [this.position]);
}

/// Wraps geolocator with the full permission/service flow.
class LocationService {
  static Future<LocationResult> current() async {
    // 1. Location services on?
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(
          false, "Geolokatsiya o'chirilgan. Iltimos, uni yoqing.");
    }

    // 2. Permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(false, "Joylashuvga ruxsat berilmadi.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(false,
          "Joylashuvga ruxsat butunlay rad etilgan. Telefon sozlamalaridan yoqing.");
    }

    // 3. Read position.
    // geolocator 12.x uses `desiredAccuracy` (NOT `locationSettings`, which is 13+).
    // If you upgrade to geolocator 13+, switch to:
    //   locationSettings: const LocationSettings(
    //     accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20))
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      return LocationResult(true, 'OK', pos);
    } catch (e) {
      return LocationResult(false, "Joylashuvni aniqlab bo'lmadi: $e");
    }
  }
}
