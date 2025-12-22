import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'constants/api_constants.dart';



class ApiService {
  /// GET Request
  static Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, String>? queryParams,}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint').replace(
      queryParameters: queryParams,
    );
    debugPrint('🌐 GET URL: $url');
    try {
      final response = await http.get(url, headers: _defaultHeaders(headers));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET request failed: $e');
      rethrow;
    }
  }

  /// POST Request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await http.post(
        url,
        headers:_defaultHeaders(headers),
        body: jsonEncode(body),

      );
      return _handleResponse(response);

    } catch (e) {
      debugPrint('POST request failed: $e');
      rethrow;
    }
  }


  /// PUT Request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await http.put(
        url,
        headers: _defaultHeaders(headers),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT request failed: $e');
      rethrow;
    }
  }

  /// DELETE Request
  static Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await http.delete(url, headers: _defaultHeaders(headers));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE request failed: $e');
      rethrow;
    }
  }

  /// Multipart Request (for file/image upload)
  static Future<dynamic> uploadFile({
    required String endpoint,
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(_defaultHeaders(headers))
      ..files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('File upload failed: $e');
      rethrow;
    }
  }

  /// Default headers with optional auth
  static Map<String, String> _defaultHeaders([Map<String, String>? custom]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?custom,
    };
    debugPrint('📦 Headers Sent: $headers');
    return headers;
  }


  /// Response handler
  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else {
      debugPrint('❌ API Error [$statusCode]: $body');
      // ✅ Pick error message directly from API response (i.e., from "error" key)
      final errorMessage = body?['error'] ?? response.reasonPhrase ?? 'Unknown error';
      throw Exception(errorMessage); // ❗ Use Exception instead of HttpException to avoid unnecessary prefix
    }
  }

}
