import 'package:zerin_marketplace/features/map/domain/map_models.dart';

abstract class DirectionsLauncher {
  Future<bool> launchDirections(MapListing listing);
}
