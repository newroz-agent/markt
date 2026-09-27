import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';

abstract interface class SellRepository {
  Future<SellerIdentity?> fetchSellerIdentity();

  Future<List<ListingTemplate>> searchTemplates(String query);

  Future<MyListing> submitListing(SellListingDraft draft);

  Future<List<MyListing>> fetchMyListings();
}

class UnconfiguredSellRepository implements SellRepository {
  const UnconfiguredSellRepository();

  Never _unconfigured() =>
      throw const AppException(AppFailureCode.backendNotConfigured);

  @override
  Future<SellerIdentity?> fetchSellerIdentity() async => null;

  @override
  Future<List<ListingTemplate>> searchTemplates(String query) async =>
      const <ListingTemplate>[];

  @override
  Future<MyListing> submitListing(SellListingDraft draft) async =>
      _unconfigured();

  @override
  Future<List<MyListing>> fetchMyListings() async => _unconfigured();
}
