import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:tour_guide/core/api/api_client.dart';

enum UploadType { profile, destination, post, bulk }

class FileUploadService {
  // Use the central base URL from ApiClient
  static String get _baseUrl => "${ApiClient.baseUrl}/api/uploads";

  static Future<List<String>> uploadFiles({
    required List<File> files,
    required UploadType type,
  }) async {
    if (files.isEmpty) return [];

    String endpoint;
    String fieldName;

    switch (type) {
      case UploadType.profile:
        endpoint = "/profile";
        fieldName = "file";
        break;
      case UploadType.destination:
        endpoint = "/destination";
        fieldName = "file";
        break;
      case UploadType.post:
        endpoint = "/post/media";
        fieldName = "files";
        break;
      case UploadType.bulk:
        endpoint = "/bulk?type=posts";
        fieldName = "files";
        break;
    }

    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Get the token from ApiClient
    final token = ApiClient.getToken();

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    });

    for (var file in files) {
      final String? mimeType = lookupMimeType(file.path);
      final contentType = mimeType != null 
          ? MediaType.parse(mimeType) 
          : MediaType('image', 'jpeg');

      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: contentType,
      );
      
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((item) => item['fileUrl'].toString()).toList();
        } else if (decoded is Map && decoded.containsKey('fileUrl')) {
          return [decoded['fileUrl'].toString()];
        }
        return [];
      } else {
        throw Exception("Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Upload error: $e");
    }
  }
}