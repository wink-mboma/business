import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../../features/products/product.dart';

class StoreCategory {
  const StoreCategory({required this.id, required this.name, required this.slug, this.imageUrl, this.productCount = 0});
  final String id, name, slug;
  final String? imageUrl;
  final int productCount;
  factory StoreCategory.fromJson(Map<String,dynamic> j) => StoreCategory(
    id: '${j['id']}', name: '${j['name'] ?? ''}', slug: '${j['slug'] ?? ''}',
    imageUrl: j['image_url'] as String?, productCount: _asInt(j['product_count']));
}
class StoreBrand {
  const StoreBrand({required this.id, required this.name, required this.slug, this.description, this.imageUrl, this.productCount = 0});
  final String id, name, slug;
  final String? description, imageUrl;
  final int productCount;
  factory StoreBrand.fromJson(Map<String,dynamic> j) => StoreBrand(
    id: '${j['id']}', name: '${j['name'] ?? ''}', slug: '${j['slug'] ?? ''}',
    description: j['description'] as String?, imageUrl: j['image_url'] as String?, productCount: _asInt(j['product_count']));
}
class StoreBanner {
  const StoreBanner({required this.id, required this.title, this.subtitle, this.imageUrl, this.productId, this.productName, this.linkUrl, this.position = 'home'});
  final String id, title, position;
  final String? subtitle, imageUrl, productId, productName, linkUrl;
  factory StoreBanner.fromJson(Map<String,dynamic> j) => StoreBanner(
    id: '${j['id']}', title: '${j['title'] ?? ''}', subtitle: j['subtitle'] as String?,
    imageUrl: j['image_url'] as String?, productId: j['target_product_id']?.toString(),
    productName: j['product_name'] as String?, linkUrl: j['link_url'] as String?, position: '${j['position'] ?? 'home'}');
}

int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
Map<String,dynamic> _map(dynamic value) => Map<String,dynamic>.from(value as Map);

class CatalogApi {
  CatalogApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Uri _uri(String endpoint, [Map<String,String>? query]) => Uri.parse('${ApiConfig.baseUrl}/$endpoint').replace(queryParameters: query);

  Future<List<dynamic>> _getList(String endpoint, [Map<String,String>? query]) async {
    final response = await _client.get(_uri(endpoint, query), headers: const {'Accept':'application/json'}).timeout(ApiConfig.timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Store API returned HTTP ${response.statusCode}.');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['success'] != true || decoded['data'] is! List) {
      throw Exception(decoded is Map ? (decoded['message']?.toString() ?? 'Invalid store API response.') : 'Invalid store API response.');
    }
    return (decoded['data'] as List).toList();
  }
  Future<List<Product>> products({String? query, String? categoryId, String? brandId, int limit = 100}) async {
    final params = <String,String>{'limit':'$limit'};
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (categoryId != null) params['category_id'] = categoryId;
    if (brandId != null) params['brand_id'] = brandId;
    return (await _getList('products.php',params)).map((v)=>Product.fromJson(_map(v))).toList();
  }
  Future<Product> productById(String id) async {
    final rows = await _getList('products.php', {'id': id, 'limit': '1'});
    if (rows.isEmpty) throw Exception('Product not found.');
    return Product.fromJson(_map(rows.first));
  }
  Future<List<StoreCategory>> categories() async => (await _getList('categories.php')).map((v)=>StoreCategory.fromJson(_map(v))).toList();
  Future<List<StoreBrand>> brands() async => (await _getList('brands.php')).map((v)=>StoreBrand.fromJson(_map(v))).toList();
  Future<List<StoreBanner>> banners() async => (await _getList('banners.php')).map((v)=>StoreBanner.fromJson(_map(v))).toList();
  void close() => _client.close();
}
