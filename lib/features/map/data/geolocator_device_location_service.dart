import 'package:geolocator/geolocator.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService({
    this.locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 12),
    ),
  });

  final LocationSettings locationSettings;

  @override
  Future<DeviceLocationResult> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const DeviceLocationResult.serviceDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocationResult.deniedForever();
      }
      if (permission == LocationPermission.denied) {
        return const DeviceLocationResult.denied();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      final point = MapPoint.tryParse(position.latitude, position.longitude);
      return point == null
          ? const DeviceLocationResult.unavailable()
          : DeviceLocationResult.available(point);
    } on LocationServiceDisabledException {
      return const DeviceLocationResult.serviceDisabled();
    } on Object {
      return const DeviceLocationResult.unavailable();
    }
  }
}
