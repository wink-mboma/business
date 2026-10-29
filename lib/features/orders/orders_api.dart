import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/api_config.dart';
import 'order_state.dart';

class OrdersApi {
  OrdersApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri get _base => Uri.parse('${ApiConfig.baseUrl}/orders.php');

  Future<List<StoreOrder>> list({required String token}) async {
    final response = await _client.get(_base, headers: _headers(token)).timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    final data = decoded['data'];
    if (data is! List) throw Exception('Invalid orders response.');
    return data.whereType<Map>().map((row) => StoreOrder.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<StoreOrder> detail({required String token, required String id}) async {
    final response = await _client.get(_base.replace(queryParameters: {'id': id}), headers: _headers(token)).timeout(ApiConfig.timeout);
    final decoded = _decode(response);
    if (decoded['data'] is! Map) throw Exception('Invalid order details response.');
    return StoreOrder.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['success'] != true) {
      throw Exception(decoded is Map ? (decoded['message']?.toString() ?? 'Could not load orders.') : 'Invalid server response.');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
