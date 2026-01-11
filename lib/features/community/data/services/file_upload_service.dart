import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // Recommended: run 'flutter pub add mime'
import 'package:flutter/foundation.dart';
enum UploadType { profile, destination, post, bulk }

class FileUploadService {
  // Your current Ngrok URL
  static const String _baseUrl = "https://zebralike-inquirable-almeda.ngrok-free.dev/api/uploads";

  static Future<List<String>> uploadFiles({
    required List<File> files,
    required UploadType type,
    required String token,
  }) async {
    if (files.isEmpty) return [];

    // 1. Determine endpoint and field names based on UploadType
    String endpoint;
    String fieldName;

    switch (type) {
      case UploadType.profile:
        endpoint = "/profile";
        fieldName = "file"; // Single file expected
        break;
      case UploadType.destination:
        endpoint = "/destination";
        fieldName = "file";
        break;
      case UploadType.post:
        endpoint = "/post/media";
        fieldName = "files"; // List of files expected
        break;
      case UploadType.bulk:
        endpoint = "/bulk?type=posts";
        fieldName = "files";
        break;
    }

    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // 2. Add Critical Headers for Security & Ngrok bypass
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    });

    // 3. Attach files with dynamic MimeType detection
    for (var file in files) {
      // lookupMimeType ensures we send image/png or image/jpeg correctly
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
      // 4. Send request with a 30-second timeout for Ngrok stability
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      // 5. Success Handling
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        // Spring Boot returns a List for multi-uploads and an Object for single ones
        if (decoded is List) {
          return decoded.map((item) => item['fileUrl'].toString()).toList();
        } else if (decoded is Map && decoded.containsKey('fileUrl')) {
          return [decoded['fileUrl'].toString()];
        }
        return [];
      } else {
        // Log error body for debugging 403 (Auth) or 413 (File too big)
        debugPrint("Upload Error [${response.statusCode}]: ${response.body}");
        throw Exception("Server Error: ${response.statusCode}");
      }
    } on SocketException {
      throw Exception("Connection failed. Ensure your ngrok tunnel is active.");
    } on TimeoutException {
      throw Exception("Upload timed out. Try fewer images or a better connection.");
    } catch (e) {
      debugPrint("FileUploadService Exception: $e");
      throw Exception("Upload failed: $e");
    }
  }

  /// Helper to delete a file from the server
  static Future<void> deleteFile(String fileUrl, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl?fileUrl=$fileUrl'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception("Delete failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("File delete error: $e");
    }
  }
}