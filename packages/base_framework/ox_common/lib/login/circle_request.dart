import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nostr_core_dart/nostr.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/log_util.dart';
import 'login_manager.dart';

/// Base error response model for Circle API
class CircleApiError {
  CircleApiError({
    required this.error,
  });

  final String error;

  factory CircleApiError.fromJson(Map<String, dynamic> json) {
    return CircleApiError(
      error: json['error'] as String,
    );
  }

  @override
  String toString() => error;
}

/// Base request handler for Circle API
/// 
/// Provides common functionality for making authenticated requests to Circle API endpoints
/// using Nostr event signatures for authentication.
class CircleRequest {
  CircleRequest._();

  /// Create and sign a Nostr event for API authentication
  /// 
  /// [kind] Event kind (default: 1)
  /// [tags] Event tags
  /// [content] Event content
  /// 
  /// Returns a signed Nostr event ready to be sent as request body.
  /// Throws [Exception] if user is not logged in or private key is not available.
  static Future<Event> _createSignedEvent({
    int kind = 1,
    List<List<String>> tags = const [],
    String content = '',
  }) async {
    // Get current account
    final loginManager = LoginManager.instance;
    final account = loginManager.currentState.account;
    if (account == null) {
      throw Exception('User not logged in');
    }

    final pubkey = account.pubkey;
    final privkey = Account.sharedInstance.currentPrivkey;
    
    if (privkey.isEmpty) {
      throw Exception('Private key not available');
    }

    // Create and sign Nostr event
    return await Event.from(
      kind: kind,
      tags: tags,
      content: content,
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  /// Make a POST request to Circle API endpoint
  /// 
  /// [endpoint] API endpoint path (e.g., '/api/relay-address')
  /// [event] Signed Nostr event to send as request body
  /// [baseUrl] Optional base URL (defaults to http://127.0.0.1:3000)
  /// 
  /// Returns the HTTP response.
  /// Throws [Exception] if the request fails.
  static Future<http.Response> _postRequest({
    required String endpoint,
    required Event event,
    String? baseUrl,
  }) async {
    final apiBaseUrl = baseUrl ?? 'http://192.168.0.18:3000';
    final url = Uri.parse('$apiBaseUrl$endpoint');

    LogUtil.d(() => 'Making POST request to: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(event.toJson()),
    );

    LogUtil.d(() => 'Response status: ${response.statusCode}');

    return response;
  }

  /// Parse response and handle errors
  /// 
  /// [response] HTTP response
  /// [parseSuccess] Function to parse successful response (status 200)
  /// 
  /// Returns parsed response data.
  /// Throws [Exception] if the request failed.
  static T _handleResponse<T>({
    required http.Response response,
    required T Function(Map<String, dynamic>) parseSuccess,
  }) {
    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      try {
        return parseSuccess(responseBody);
      } catch (e) {
        LogUtil.e(() => 'Error parsing response: $e');
        throw Exception('Failed to parse response: $e');
      }
    } else {
      // Handle error response
      try {
        final error = CircleApiError.fromJson(responseBody);
        LogUtil.e(() => 'API error: ${error.error}');
        throw Exception(error.error);
      } catch (e) {
        if (e is Exception && e.toString().contains('error')) {
          rethrow;
        }
        LogUtil.e(() => 'Unknown error response: ${response.body}');
        throw Exception('Request failed with status ${response.statusCode}: ${response.body}');
      }
    }
  }

  /// Make an authenticated POST request to Circle API
  /// 
  /// [endpoint] API endpoint path (e.g., '/api/relay-address')
  /// [parseSuccess] Function to parse successful response
  /// [kind] Event kind (default: 1)
  /// [tags] Event tags
  /// [content] Event content
  /// [baseUrl] Optional base URL (defaults to http://127.0.0.1:3000)
  /// 
  /// Returns parsed response data.
  /// Throws [Exception] if the request fails or user is not logged in.
  static Future<T> post<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) parseSuccess,
    int kind = 1,
    List<List<String>> tags = const [],
    String content = '',
    String? baseUrl,
  }) async {
    try {
      // Create signed event
      final event = await _createSignedEvent(
        kind: kind,
        tags: tags,
        content: content,
      );

      // Make request
      final response = await _postRequest(
        endpoint: endpoint,
        event: event,
        baseUrl: baseUrl,
      );

      // Parse and return response
      return _handleResponse(
        response: response,
        parseSuccess: parseSuccess,
      );
    } catch (e) {
      LogUtil.e(() => 'Error in CircleRequest.post: $e');
      rethrow;
    }
  }
}

