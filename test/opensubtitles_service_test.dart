import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dubsubs/models/opensubtitles_result.dart';
import 'package:dubsubs/services/opensubtitles_service.dart';

// A trimmed, real response captured from api.opensubtitles.com/api/v1/subtitles
// (query=inception&languages=en) — fields not read by OpenSubtitlesResult are
// dropped for brevity.
const _searchResponseJson = '''
{
  "total_pages": 2,
  "total_count": 56,
  "data": [
    {
      "id": "4859512",
      "attributes": {
        "language": "en",
        "download_count": 7721,
        "hearing_impaired": false,
        "release": "Inception",
        "uploader": {"name": "coolgit"},
        "feature_details": {"title": "Inception", "year": 2010},
        "files": [{"file_id": 4982777, "file_name": "Inception"}]
      }
    },
    {
      "id": "no-file",
      "attributes": {
        "language": "en",
        "download_count": 1,
        "release": "No files here",
        "files": []
      }
    }
  ]
}
''';

const _downloadResponseJson = '''
{"link": "https://example.com/download/abc/Inception.srt", "file_name": "Inception.srt", "remaining": 99}
''';

const _sampleSrt = '1\n00:00:01,000 --> 00:00:02,000\nHello\n';

void main() {
  group('OpenSubtitlesResult.fromJson', () {
    test('parses a well-formed entry', () {
      final data =
          (jsonDecode(_searchResponseJson) as Map<String, dynamic>)['data'] as List<dynamic>;
      final result = OpenSubtitlesResult.fromJson(data[0] as Map<String, dynamic>);

      expect(result, isNotNull);
      expect(result!.fileId, 4982777);
      expect(result.language, 'en');
      expect(result.movieTitle, 'Inception');
      expect(result.year, 2010);
      expect(result.uploaderName, 'coolgit');
      expect(result.downloadCount, 7721);
      expect(result.displayTitle, 'Inception (2010)');
    });

    test('returns null when there are no files', () {
      final data =
          (jsonDecode(_searchResponseJson) as Map<String, dynamic>)['data'] as List<dynamic>;
      final result = OpenSubtitlesResult.fromJson(data[1] as Map<String, dynamic>);
      expect(result, isNull);
    });
  });

  group('OpenSubtitlesService', () {
    test('search returns parsed, file-having results only', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/subtitles');
        expect(request.headers['Api-Key'], 'test-key');
        return http.Response(_searchResponseJson, 200);
      });

      final service = OpenSubtitlesService(client: client, apiKey: 'test-key');
      final results = await service.search(query: 'inception', languageCode: 'en');

      expect(results, hasLength(1));
      expect(results.single.displayTitle, 'Inception (2010)');
    });

    test('search throws without an API key', () async {
      final service = OpenSubtitlesService(client: MockClient((_) async => http.Response('', 200)));
      expect(
        () => service.search(query: 'inception', languageCode: 'en'),
        throwsA(isA<OpenSubtitlesException>()),
      );
    });

    test('search surfaces a clear error on 401', () async {
      final client = MockClient((request) async => http.Response('', 401));
      final service = OpenSubtitlesService(client: client, apiKey: 'bad-key');
      expect(
        () => service.search(query: 'inception', languageCode: 'en'),
        throwsA(isA<OpenSubtitlesException>()),
      );
    });

    test('search surfaces a clear error on 406 (quota exceeded)', () async {
      final client = MockClient((request) async => http.Response('', 406));
      final service = OpenSubtitlesService(client: client, apiKey: 'test-key');
      expect(
        () => service.search(query: 'inception', languageCode: 'en'),
        throwsA(
          isA<OpenSubtitlesException>().having((e) => e.message, 'message', contains('limit')),
        ),
      );
    });

    test('downloadSrtText follows the download link and returns file text', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/download') {
          return http.Response(_downloadResponseJson, 200);
        }
        if (request.url.toString() == 'https://example.com/download/abc/Inception.srt') {
          return http.Response(_sampleSrt, 200);
        }
        return http.Response('not found', 404);
      });

      final service = OpenSubtitlesService(client: client, apiKey: 'test-key');
      final text = await service.downloadSrtText(4982777);
      expect(text, _sampleSrt);
    });
  });
}
