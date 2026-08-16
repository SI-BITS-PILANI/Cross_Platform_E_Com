import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/auth_response.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.apiBase,
        _client = client ?? http.Client();

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);

    return _processResponse(response);
  }

  Future<List<dynamic>> getListJson(
    String path, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List<dynamic>) {
        return body;
      }
      throw const FormatException('Expected a list response body');
    }

    if (body is Map<String, dynamic>) {
      throw AuthError.fromJson(body);
    }

    throw Exception('Request failed with status ${response.statusCode}');
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw AuthError.fromJson(body);
  }
}
