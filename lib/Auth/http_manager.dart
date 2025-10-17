import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Custom HTTP exception with full error context
class HttpException implements Exception {
  /// Human-readable error message (from server or fallback)
  final String message;

  /// HTTP status code, if available (e.g. 404, 500, etc.)
  final int? statusCode;

  /// The original caught error (useful for debugging)
  final Object? originalError;

  /// The stack trace when the error occurred
  final StackTrace? stackTrace;

  HttpException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final code = statusCode != null ? ' ($statusCode)' : '';
    final origin = originalError != null ? '\nCaused by: $originalError' : '';
    final trace = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    return 'HttpException$code: $message$origin$trace';
  }
}

/// HTTP Manager
class HttpManager {
  static final http.Client client = http.Client(); // Global singleton client
  final Duration timeout;
  final bool skipAuthHeader;
  final Future<DateTime?> Function()? refreshFunction;

  late final String apiBaseUrl;

  HttpManager({
    this.timeout = const Duration(seconds: 8),
    this.skipAuthHeader = false,
    this.refreshFunction,
    // required this.repoPath,
  }) {
    final apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      throw Exception("Missing API_URL in .env file");
    }
    // Normalize both parts and safely combine
    apiBaseUrl =
        apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
  }

  /// Build headers (merge default + custom headers)
  Future<Map<String, String>> _buildHeaders([
    Map<String, String>? headers,
  ]) async {
    final defaultHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    return defaultHeaders;
  }

  /// Unified request handler with optional token refresh on 401
  Future<http.Response> _request(
    Future<http.Response> Function(Map<String, String> headersEx) fn,
  ) async {
    try {
      var headers = await _buildHeaders();
      var response = await fn(headers).timeout(timeout);

      // success Return response:
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      String? serverMessage;
      // Handle 401 with token refresh and retry once

      if (response.statusCode == 401 && refreshFunction != null) {
        debugPrint('refresh is calling in the httpManager');
        final access = await refreshFunction!();
        if (access == null) {
          throw Exception(
            'After refreshing session, access token found to be null',
          );
        }
        headers = await _buildHeaders();
        response = await fn(headers).timeout(timeout);
      }
      // debugPrint(response.statusCode.toString());

      // debugPrint(response.body);
      if (response.statusCode == 404) {
        throw http.ClientException(
          'Not Found',
          Uri.parse(response.request?.url.toString() ?? 'unknown'),
        );
      }

      // Try to extract "detail" message from the response body

      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['detail'] is String) {
          serverMessage = body['detail'];
        }
      } catch (_) {
        // ignore non-JSON bodies
      }

      // Fallback message
      String message = serverMessage ?? 'Check your network';
      if (message.contains('Not Found')) message = 'Something Wrong';
      //  Throw a ClientException including code and detail
      throw http.ClientException(
        message,
        Uri.parse(response.request?.url.toString() ?? 'unknown'),
      );
    } on SocketException catch (e, st) {
      throw HttpException(
        'No internet connection',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      throw HttpException(
        'Taking too long... Try again',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      throw HttpException(e.message, originalError: e, stackTrace: st);
    } catch (e) {
      throw 'Something went wrong';
    }
  }

  // h -> default header build by _buildheader:
  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      _request((h) async {
        return client.get(uri, headers: {...h, ...?headers});
      });

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _request(
    (h) => client.post(uri, headers: {...h, ...?headers}, body: body),
  );

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _request(
    (h) => client.put(uri, headers: {...h, ...?headers}, body: body),
  );

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _request(
    (h) => client.delete(uri, headers: {...h, ...?headers}, body: body),
  );

  /// Close client (optional, usually never called)
  static void dispose() => client.close();
}
