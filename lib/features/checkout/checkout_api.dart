import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/api_config.dart';

class CheckoutApi {
  CheckoutApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Uri get _url => Uri.parse('${ApiConfig.baseUrl}/checkout.php');

  Future<Map<String, dynamic>> createOrder({
    required String token,
    required List<Map<String, dynamic>> items,
    required String address,
    required String phone,
  }) async {
    final response = await _client
        .post(
          _url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'items': items,
            'shipping_address': address,
            'phone': phone,
          }),
        )
        .timeout(ApiConfig.timeout);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception(
        decoded is Map
            ? (decoded['message']?.toString() ?? 'Could not create your order.')
            : 'Invalid checkout response.',
      );
    }
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> verify({
    required String token,
    required String txRef,
  }) async {
    final response = await _client
        .get(
          _url.replace(queryParameters: {'tx_ref': txRef}),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.timeout);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception(
        decoded is Map
            ? (decoded['message']?.toString() ?? 'Could not verify payment.')
            : 'Invalid payment response.',
      );
    }
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }
}
