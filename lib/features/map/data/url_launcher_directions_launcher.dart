import 'package:url_launcher/url_launcher.dart';
import 'package:zerin_marketplace/features/map/domain/directions_launcher.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';

typedef ExternalDirectionsOpener = Future<bool> Function(Uri uri);

/// Builds directions only for the server-approved precise-business projection.
/// Approximate private/listing points must never be presented as destinations.
Uri? buildExternalDirectionsUri(MapListing listing) {
  if (!listing.isPreciseBusiness) return null;
  final destination = [
    listing.marker.latitude.toStringAsFixed(6),
    listing.marker.longitude.toStringAsFixed(6),
  ].join(',');
  return Uri.https('www.google.com', '/maps/dir/', <String, String>{
    'api': '1',
    'destination': destination,
  });
}

class UrlLauncherDirectionsLauncher implements DirectionsLauncher {
  UrlLauncherDirectionsLauncher({ExternalDirectionsOpener? opener})
    : _opener = opener ?? _openExternally;

  final ExternalDirectionsOpener _opener;

  Uri? buildUri(MapListing listing) => buildExternalDirectionsUri(listing);

  @override
  Future<bool> launchDirections(MapListing listing) async {
    final uri = buildUri(listing);
    if (uri == null) return false;
    return _opener(uri);
  }

  static Future<bool> _openExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
