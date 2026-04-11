import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/misa.dart';

abstract class MisaService {
  const MisaService();

  Future<MisaAiReply> submit(MisaRequest request);
}

class MisaServiceException implements Exception {
  const MisaServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkMisaService implements MisaService {
  const NetworkMisaService({this.baseUrl});

  final String? baseUrl;

  @override
  Future<MisaAiReply> submit(MisaRequest request) async {
    final response = await http.post(
      _endpoint,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    final decoded = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['error'] as String? ??
              decoded['message'] as String? ??
              'MISA request failed.')
          : 'MISA request failed.';
      throw MisaServiceException(message);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const MisaServiceException(
        'MISA returned an invalid response.',
      );
    }

    final reply = MisaAiReply.fromJson(decoded);
    if (reply.message.isEmpty) {
      throw const MisaServiceException(
        'MISA returned an empty response.',
      );
    }
    return reply;
  }

  Object? _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Uri get _endpoint {
    final configured = baseUrl?.trim();
    final resolvedBase = (configured != null && configured.isNotEmpty)
        ? configured
        : const String.fromEnvironment(
            'MISA_API_BASE_URL',
            defaultValue: 'https://ekutir-agent-app.pages.dev',
          );

    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        // Reroute to remote function if testing web locally
        return Uri.parse(resolvedBase).resolve('/api/misa');
      }
      return Uri.base.resolve('/api/misa');
    }

    return Uri.parse(resolvedBase).resolve('/api/misa');
  }
}
