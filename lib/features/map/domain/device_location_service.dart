import 'package:flutter/foundation.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';

enum DeviceLocationStatus {
  notRequested,
  requesting,
  available,
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}

@immutable
class DeviceLocationResult {
  const DeviceLocationResult._(this.status, {this.point});

  const DeviceLocationResult.available(MapPoint point)
    : this._(DeviceLocationStatus.available, point: point);

  const DeviceLocationResult.denied() : this._(DeviceLocationStatus.denied);

  const DeviceLocationResult.deniedForever()
    : this._(DeviceLocationStatus.deniedForever);

  const DeviceLocationResult.serviceDisabled()
    : this._(DeviceLocationStatus.serviceDisabled);

  const DeviceLocationResult.unavailable()
    : this._(DeviceLocationStatus.unavailable);

  final DeviceLocationStatus status;
  final MapPoint? point;

  bool get isAvailable =>
      status == DeviceLocationStatus.available && point != null;
}

abstract class DeviceLocationService {
  /// Requests one foreground position. Implementations must not persist it.
  Future<DeviceLocationResult> getCurrentLocation();
}
