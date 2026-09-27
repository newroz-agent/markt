import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';

abstract interface class SellImageService {
  Future<List<SellPhoto>> pickFromGallery();
  Future<SellPhoto?> takePhoto();
  Future<SellPhoto?> importTemplateImage(String imageUrl);
}

class UnavailableSellImageService implements SellImageService {
  const UnavailableSellImageService();

  @override
  Future<List<SellPhoto>> pickFromGallery() async => const <SellPhoto>[];

  @override
  Future<SellPhoto?> takePhoto() async => null;

  @override
  Future<SellPhoto?> importTemplateImage(String imageUrl) async => null;
}
