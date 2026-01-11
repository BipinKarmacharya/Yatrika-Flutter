// import 'dart:io';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../core/api/api_client.dart';

// class UploadService {
//   static Future<Map<String, dynamic>> uploadProfile(File file) async {
//     final uri = Uri.parse('${ApiClient.baseUrl}/api/uploads/profile');
//     final req = http.MultipartRequest('POST', uri);
//     req.headers.addAll(ApiClient.headers());
//     req.files.add(await http.MultipartFile.fromPath('file', file.path));
//     final res = await req.send();
//     final body = await res.stream.bytesToString();
//     if (res.statusCode >= 200 && res.statusCode < 300) {
//       return body.isEmpty ? {} : (jsonDecode(body) as Map<String, dynamic>);
//     }
//     throw Exception('Upload failed: ${res.statusCode}');
//   }

//   static Future<Map<String, dynamic>> uploadPostMedia(File file) async {
//     final uri = Uri.parse('${ApiClient.baseUrl}/api/uploads/post/media');
//     final req = http.MultipartRequest('POST', uri);
//     req.headers.addAll(ApiClient.headers());
//     req.files.add(await http.MultipartFile.fromPath('file', file.path));
//     final res = await req.send();
//     final body = await res.stream.bytesToString();
//     if (res.statusCode >= 200 && res.statusCode < 300) {
//       return body.isEmpty ? {} : (jsonDecode(body) as Map<String, dynamic>);
//     }
//     throw Exception('Upload failed: ${res.statusCode}');
//   }
// }
