import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/opensubtitles_result.dart';

class OpenSubtitlesException implements Exception {
  final String message;
  OpenSubtitlesException(this.message);

  @override
  String toString() => message;
}

const webUnsupportedMessage =
    "OpenSubtitles search isn't available in the web build: their API requires "
    'a custom User-Agent header, which browsers block scripts from setting, and '
    "their server also rejects the browser's CORS preflight. This works fine on "
    'the Android/iOS app. On web, import an .srt file directly instead.';

/// Thin client for the OpenSubtitles.com REST API (https://opensubtitles.com),
/// the same open subtitle database VLC and other players use.
///
/// Uses only the API key (no user login), which OpenSubtitles allows with a
/// modest daily download quota shared across the key. Search requires
/// internet; once a subtitle is downloaded, DubSubs stores it locally and
/// playback is fully offline from then on, same as a manually-imported file.
class OpenSubtitlesService {
  OpenSubtitlesService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? Config.openSubtitlesApiKey;

  final http.Client _client;
  final String _apiKey;

  bool get hasApiKey => _apiKey.isNotEmpty;

  static const _baseUrl = 'https://api.opensubtitles.com/api/v1';

  Map<String, String> get _headers => {
    'Api-Key': _apiKey,
    'User-Agent': 'DubSubs v1.0.0',
    'Accept': 'application/json',
  };

  Future<List<OpenSubtitlesResult>> search({
    required String query,
    required String languageCode,
  }) async {
    if (kIsWeb) throw OpenSubtitlesException(webUnsupportedMessage);
    if (!hasApiKey) {
      throw OpenSubtitlesException(
        'No OpenSubtitles API key configured. See README.md for setup.',
      );
    }
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/subtitles').replace(queryParameters: {
      'query': query.trim(),
      'languages': languageCode,
    });

    final response = await _get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];

    return data
        .cast<Map<String, dynamic>>()
        .map(OpenSubtitlesResult.fromJson)
        .whereType<OpenSubtitlesResult>()
        .toList();
  }

  /// Downloads the subtitle file and returns its decoded text content.
  Future<String> downloadSrtText(int fileId) async {
    if (kIsWeb) throw OpenSubtitlesException(webUnsupportedMessage);
    if (!hasApiKey) {
      throw OpenSubtitlesException(
        'No OpenSubtitles API key configured. See README.md for setup.',
      );
    }

    final downloadResponse = await _post(
      Uri.parse('$_baseUrl/download'),
      body: jsonEncode({'file_id': fileId}),
    );
    final downloadBody = jsonDecode(downloadResponse.body) as Map<String, dynamic>;
    final link = downloadBody['link'] as String?;
    if (link == null) {
      final message = downloadBody['message'] as String?;
      throw OpenSubtitlesException(message ?? 'OpenSubtitles did not return a download link.');
    }

    final fileResponse = await _client.get(Uri.parse(link));
    if (fileResponse.statusCode != 200) {
      throw OpenSubtitlesException('Could not download the subtitle file.');
    }

    try {
      return utf8.decode(fileResponse.bodyBytes);
    } catch (_) {
      return latin1.decode(fileResponse.bodyBytes);
    }
  }

  Future<http.Response> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } catch (_) {
      throw OpenSubtitlesException('Could not reach OpenSubtitles. Check your connection.');
    }
    _checkStatus(response);
    return response;
  }

  Future<http.Response> _post(Uri uri, {required String body}) async {
    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: body,
      );
    } catch (_) {
      throw OpenSubtitlesException('Could not reach OpenSubtitles. Check your connection.');
    }
    _checkStatus(response);
    return response;
  }

  void _checkStatus(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 401:
        throw OpenSubtitlesException('OpenSubtitles rejected the API key.');
      case 403:
        throw OpenSubtitlesException(
          'OpenSubtitles blocked this request (403). Try again later.',
        );
      case 406:
        throw OpenSubtitlesException("You've hit today's OpenSubtitles download limit.");
      case 429:
        throw OpenSubtitlesException('Too many OpenSubtitles requests — try again shortly.');
      default:
        throw OpenSubtitlesException('OpenSubtitles error (${response.statusCode}).');
    }
  }

  void dispose() => _client.close();
}
