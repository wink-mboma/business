import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/products/product.dart';
import 'catalog_api.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) {
  final api = CatalogApi();
  ref.onDispose(api.close);
  return api;
});
final catalogProductsProvider = FutureProvider<List<Product>>((ref) => ref.watch(catalogApiProvider).products());
final catalogCategoriesProvider = FutureProvider<List<StoreCategory>>((ref) => ref.watch(catalogApiProvider).categories());
final catalogBrandsProvider = FutureProvider<List<StoreBrand>>((ref) => ref.watch(catalogApiProvider).brands());
final catalogBannersProvider = FutureProvider<List<StoreBanner>>((ref) => ref.watch(catalogApiProvider).banners());

final catalogSearchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) => ref.watch(catalogApiProvider).products(query: query, limit: 100));
final catalogProductByIdProvider = FutureProvider.family<Product, String>((ref, id) => ref.watch(catalogApiProvider).productById(id));
final catalogFilteredProductsProvider = FutureProvider.family<List<Product>, String>((ref, key) {
  final parts = key.split('|');
  final categoryId = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
  final brandId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  return ref.watch(catalogApiProvider).products(categoryId: categoryId, brandId: brandId, limit: 100);
});
