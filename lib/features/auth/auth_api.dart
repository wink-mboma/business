import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_config.dart';

class CustomerAccount {
  const CustomerAccount({required this.id, required this.name, required this.email, this.phone = '', this.address, this.profileImageUrl});
  final String id, name, email;
  final String phone;
  final String? address;
  final String? profileImageUrl;
  factory CustomerAccount.fromJson(Map<String, dynamic> json) => CustomerAccount(
    id: '${json['id'] ?? ''}', name: '${json['name'] ?? ''}', email: '${json['email'] ?? ''}',
    phone: '${json['phone'] ?? ''}', address: json['address']?.toString(), profileImageUrl: json['profile_image_url']?.toString() ?? json['profile_image']?.toString(),
  );
}

class AuthResult {
  const AuthResult({required this.token, required this.customer});
  final String token;
  final CustomerAccount customer;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Uri get _url => Uri.parse('${ApiConfig.baseUrl}/auth.php');
  static const tokenKey = 'mono_store_customer_token_v1';

  Future<AuthResult> _send(Map<String, dynamic> body) async {
    final response = await _client.post(_url, headers: const {'Accept':'application/json','Content-Type':'application/json'}, body: jsonEncode(body)).timeout(ApiConfig.timeout);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['success'] != true || decoded['data'] is! Map) {
      final message = decoded is Map ? (decoded['message']?.toString() ?? 'Authentication failed.') : 'Invalid authentication response.';
      throw Exception(message);
    }
    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty || data['customer'] is! Map) throw Exception('The server returned an incomplete account response.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    return AuthResult(token: token, customer: CustomerAccount.fromJson(Map<String, dynamic>.from(data['customer'] as Map)));
  }

  Future<AuthResult> login(String email, String password) => _send({'action':'login','email':email.trim(),'password':password});
  Future<AuthResult> register({required String name, required String email, required String phone, required String password}) => _send({'action':'register','name':name.trim(),'email':email.trim(),'phone':phone.trim(),'password':password});

  Future<CustomerAccount> uploadProfileImage(String token, String fileName, List<int> bytes) async {
    final uri=Uri.parse('${ApiConfig.baseUrl}/profile.php');
    final request=http.MultipartRequest('POST',uri)..headers['Authorization']='Bearer $token'..fields['action']='upload_photo';
    request.files.add(http.MultipartFile.fromBytes('photo',bytes,filename:fileName));
    final streamed=await request.send().timeout(ApiConfig.timeout); final response=await http.Response.fromStream(streamed); final decoded=jsonDecode(response.body);
    if(response.statusCode<200||response.statusCode>=300||decoded is! Map||decoded['success']!=true||decoded['data'] is! Map) throw Exception(decoded is Map?(decoded['message']??'Could not upload profile photo').toString():'Invalid profile response');
    final data=Map<String,dynamic>.from(decoded['data'] as Map); final customer=data['customer'];
    if(customer is! Map) throw Exception('The server did not return the updated profile');
    return CustomerAccount.fromJson(Map<String,dynamic>.from(customer));
  }

  Future<String?> savedToken() async => (await SharedPreferences.getInstance()).getString(tokenKey);
  Future<void> saveToken(String token) async => (await SharedPreferences.getInstance()).setString(tokenKey, token);
  Future<void> clearToken() async => (await SharedPreferences.getInstance()).remove(tokenKey);

  Future<CustomerAccount> me(String token) async {
    final response = await _client.get(_url, headers: {'Accept':'application/json','Authorization':'Bearer $token'}).timeout(ApiConfig.timeout);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded is! Map || decoded['success'] != true || decoded['data'] is! Map) throw Exception('Your session has expired. Please sign in again.');
    final data = Map<String,dynamic>.from(decoded['data'] as Map);
    return CustomerAccount.fromJson(Map<String,dynamic>.from(data['customer'] as Map));
  }

  Future<void> logout(String token) async {
    try { await _client.post(_url, headers: {'Content-Type':'application/json','Authorization':'Bearer $token'}, body: jsonEncode({'action':'logout'})).timeout(ApiConfig.timeout); } catch (_) {}
    await clearToken();
  }
}
