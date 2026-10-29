import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/api_config.dart';

class ChatApi {
  Future<dynamic> request(String token,String method,{Map<String,String>? query,Map<String,dynamic>? body}) async {
    final uri=Uri.parse('${ApiConfig.baseUrl}/chat.php').replace(queryParameters:query);
    final response=await (method=='GET'?http.get(uri,headers:{'Authorization':'Bearer $token','Accept':'application/json'}).timeout(ApiConfig.timeout):http.post(uri,headers:{'Authorization':'Bearer $token','Content-Type':'application/json','Accept':'application/json'},body:jsonEncode(body)).timeout(ApiConfig.timeout));
    final data=jsonDecode(utf8.decode(response.bodyBytes));if(response.statusCode<200||response.statusCode>=300||data is! Map||data['success']!=true)throw Exception(data is Map?(data['message']??'Chat request failed').toString():'Chat request failed');return data['data'];
  }
  Future<List<Map<String,dynamic>>> list(String token) async => ((await request(token,'GET')) as List).cast<Map<String,dynamic>>();
  Future<Map<String,dynamic>> start(String token,String productId) async => Map<String,dynamic>.from(await request(token,'POST',body:{'action':'start','product_id':productId}));
  Future<Map<String,dynamic>> thread(String token,String id) async => Map<String,dynamic>.from(await request(token,'GET',query:{'id':id}));
  Future<Map<String,dynamic>> send(String token,String id,String message) async => Map<String,dynamic>.from(await request(token,'POST',body:{'action':'send','conversation_id':id,'message':message}));
  Future<Map<String,dynamic>> sendAttachment(String token,String id,{required String fileName,required List<int> bytes,required String mimeType,required String message}) async {
    final uri=Uri.parse('${ApiConfig.baseUrl}/chat.php'); final req=http.MultipartRequest('POST',uri)..headers['Authorization']='Bearer $token'..fields['action']='send_attachment'..fields['conversation_id']=id..fields['message']=message;
    req.files.add(http.MultipartFile.fromBytes('attachment',bytes,filename:fileName));
    final streamed=await req.send().timeout(ApiConfig.timeout);final response=await http.Response.fromStream(streamed);final data=jsonDecode(utf8.decode(response.bodyBytes));if(response.statusCode<200||response.statusCode>=300||data is! Map||data['success']!=true)throw Exception(data is Map?(data['message']??'Attachment upload failed').toString():'Attachment upload failed');return Map<String,dynamic>.from(data['data'] as Map);
  }
}
