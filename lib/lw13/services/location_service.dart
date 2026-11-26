import 'package:geolocator/geolocator.dart';

/// Outcome of one GPS request. The screen switches over it, so every
/// failure has its own message and nothing throws into the UI.
sealed class LocationResult {
  const LocationResult();
}

class LocationFix extends LocationResult {
  final double latitude;
  final double longitude;
  final double altitude;

  /// Radius in meters.
  final double accuracy;
  final DateTime timestamp;

  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });
}

/// GPS is switched off in the device settings.
class LocationServicesDisabled extends LocationResult {
  const LocationServicesDisabled();
}

/// The user tapped "Don't allow". We may ask again next time.
class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied();
}

/// "Don't ask again" on Android / denied once on iOS. The system no longer
/// shows the prompt, only the app settings can change it.
class LocationPermissionDeniedForever extends LocationResult {
  const LocationPermissionDeniedForever();
}

class LocationFailure extends LocationResult {
  final String message;

  const LocationFailure(this.message);
}

/// GPS hardware access. An interface, so widget tests use a fake.
abstract interface class LocationService {
  Future<LocationResult> currentLocation();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationResult> currentLocation() async {
    try {
      // 1. Services switch (GPS on/off) comes before permissions: with GPS
      // off, a granted permission still gives no fix.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServicesDisabled();
      }

      // 2. Runtime permission: check first, ask only when needed.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionDeniedForever();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationPermissionDenied();
      }

      // 3. The fix. `locationSettings.accuracy` replaces the deprecated
      // `desiredAccuracy: LocationAccuracy.high` parameter. The time limit
      // keeps the spinner from turning forever indoors.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationFix(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } on LocationServiceDisabledException {
      return const LocationServicesDisabled();
    } on PermissionDeniedException {
      return const LocationPermissionDenied();
    } catch (e) {
      return const LocationFailure('Не удалось определить координаты');
    }
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
