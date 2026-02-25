import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Centralized HTTP client for all backend API calls.
/// Automatically attaches the Firebase ID token as a Bearer header.
class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static ApiService? _instance;
  factory ApiService() => _instance ??= ApiService._();
  ApiService._();

  /// Callback triggered on 401 (unauthorized) responses.
  /// Set this from main.dart to redirect to login.
  void Function()? onUnauthorized;

  /// Get the current Firebase ID token, or null if not signed in.
  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Build headers with Authorization and Content-Type.
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Perform a GET request. Returns decoded JSON or throws.
  Future<dynamic> get(String path) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Perform a POST request. Returns decoded JSON or throws.
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Perform a PUT request. Returns decoded JSON or throws.
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Handle the HTTP response: parse JSON, handle 401.
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException('Unauthorized – please log in again.', 401);
    }
    if (response.statusCode >= 400) {
      String message = 'Request failed';
      try {
        final body = jsonDecode(response.body);
        message = body['error'] ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
