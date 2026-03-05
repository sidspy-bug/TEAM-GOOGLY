import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Centralized HTTP client for all backend API calls.
/// Automatically attaches the Firebase ID token as a Bearer header.
/// Detects Codespace environment and adjusts the API URL accordingly.
class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      // In a browser, derive backend URL from the page's own URL.
      // Codespace ports follow: *-PORT.app.github.dev
      final pageUrl = Uri.base;
      final host = pageUrl.host; // e.g. name-8080.app.github.dev
      if (host.contains('.app.github.dev')) {
        // Replace the port portion in the Codespace hostname
        final backendHost = host.replaceFirst(RegExp(r'-\d+\.'), '-3000.');
        return '${pageUrl.scheme}://$backendHost';
      }
    }
    return 'http://localhost:3000';
  }

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
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw _mapNetworkError(e);
    }
  }

  /// Perform a POST request. Returns decoded JSON or throws.
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw _mapNetworkError(e);
    }
  }

  /// Perform a PUT request. Returns decoded JSON or throws.
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _headers();
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw _mapNetworkError(e);
    }
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

  Exception _mapNetworkError(Object error) {
    final msg = error.toString();
    final isCodespacesHost = baseUrl.contains('.app.github.dev');
    final failedFetch = msg.contains('Failed to fetch') || msg.contains('ClientException');

    if (isCodespacesHost && failedFetch) {
      return ApiException(
        'Cannot reach backend. In Codespaces, make sure port 3000 is running and set to Public in the Ports panel.',
        0,
      );
    }

    return ApiException('Network error: $msg', 0);
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
