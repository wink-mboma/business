
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';


class CustomerAddressesApi {
  CustomerAddressesApi({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _url =>
      Uri.parse('${ApiConfig.baseUrl}/customer_addresses.php');

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _send({
    required String method,
    required String token,
    Map<String, dynamic>? body,
    String? id,
  }) async {
    var uri = _url;

    if (id != null && method == 'DELETE') {
      uri = uri.replace(
        queryParameters: {'id': id},
      );
    }

    final headers = _headers(token);
    late http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
        break;
      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      default:
        throw Exception('Unsupported request method: $method');
    }

    Map<String, dynamic> result;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid API response.');
      }
      result = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception(
        'The address server returned an invalid response '
            '(${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(
        result['message']?.toString() ??
            'Address request failed (${response.statusCode}).',
      );
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAddresses({
    required String token,
  }) async {
    final result = await _send(
      method: 'GET',
      token: token,
    );

    final data = result['data'];

    if (data is! List) {
      throw Exception('The server returned an invalid address list.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createAddress({
    required String token,
    required String name,
    required String phone,
    required String address,
    required String area,
    bool isDefault = false,
  }) async {
    final result = await _send(
      method: 'POST',
      token: token,
      body: {
        'name': name,
        'phone': phone,
        'address': address,
        'area': area,
        'is_default': isDefault,
      },
    );

    final data = result['data'];

    if (data is! Map) {
      throw Exception('The server did not return the saved address.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<void> setDefault({
    required String token,
    required String id,
  }) async {
    await _send(
      method: 'PUT',
      token: token,
      body: {
        'id': id,
        'is_default': true,
      },
    );
  }

  Future<void> updateAddress({
    required String token,
    required String id,
    required String name,
    required String phone,
    required String address,
    required String area,
  }) async {
    await _send(
      method: 'PUT',
      token: token,
      body: {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'area': area,
      },
    );
  }

  Future<void> deleteAddress({
    required String token,
    required String id,
  }) async {
    await _send(
      method: 'DELETE',
      token: token,
      id: id,
    );
  }
}
