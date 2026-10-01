import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';

abstract interface class IdentityCatalogRepository {
  Future<IdentityCatalog> fetchMyIdentityCatalog();
}

class UnconfiguredIdentityCatalogRepository
    implements IdentityCatalogRepository {
  const UnconfiguredIdentityCatalogRepository();

  @override
  Future<IdentityCatalog> fetchMyIdentityCatalog() =>
      Future.error(const AppException(AppFailureCode.backendNotConfigured));
}
