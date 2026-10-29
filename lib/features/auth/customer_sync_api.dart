import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/api_config.dart';

class CustomerSyncApi {
  CustomerSyncApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Uri get _url => Uri.parse('${ApiConfig.baseUrl}/customer_sync.php');

  Future<Map<String,dynamic>> fetch(String token) async {
    final r=await _client.get(_url,headers:{'Accept':'application/json','Authorization':'Bearer $token'}).timeout(ApiConfig.timeout);
    final d=jsonDecode(utf8.decode(r.bodyBytes));
    if(r.statusCode<200||r.statusCode>=300||d is! Map||d['success']!=true||d['data'] is! Map) throw Exception(d is Map?(d['message']?.toString()??'Could not sync account data.'):'Invalid account sync response.');
    return Map<String,dynamic>.from(d['data'] as Map);
  }
  Future<void> save(String token,{required List<Map<String,dynamic>> cart,required List<String> wishlist}) async {
    final r=await _client.post(_url,headers:{'Accept':'application/json','Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'mode':'replace','cart':cart,'wishlist':wishlist})).timeout(ApiConfig.timeout);
    final d=jsonDecode(utf8.decode(r.bodyBytes));
    if(r.statusCode<200||r.statusCode>=300||d is! Map||d['success']!=true) throw Exception(d is Map?(d['message']?.toString()??'Could not save account data.'):'Invalid account sync response.');
  }
}
