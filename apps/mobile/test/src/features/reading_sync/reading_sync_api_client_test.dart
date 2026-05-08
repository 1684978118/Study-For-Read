import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/reading_sync/data/reading_sync_api_client.dart';

void main() {
  const fingerprint =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  test('upsertBookMetadata sends metadata only', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'PUT');
      expect(options.path, '/api/v1/reading/books/$fingerprint');
      expect(options.data, {
        'title': 'Kokoro',
        'author': 'Soseki',
        'fileType': 'txt',
        'sourceLang': 'ja',
        'targetLang': 'zh-CN',
        'chapterCount': 42,
      });
      _expectNoRawContentFields(options.data as Map);
      return _ok({'bookFingerprint': fingerprint});
    });
    final client = ReadingSyncApiClient(dio: _dio(adapter));

    await client.upsertBookMetadata(
      bookFingerprint: fingerprint,
      title: 'Kokoro',
      author: 'Soseki',
      fileType: 'txt',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      chapterCount: 42,
    );
  });

  test('updateReadingProgress sends progress only', () async {
    final lastReadAt = DateTime.utc(2026, 5, 8, 10, 30);
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'PATCH');
      expect(options.path, '/api/v1/reading/books/$fingerprint/progress');
      expect(options.data, {
        'currentChapterIndex': 3,
        'currentParagraphIndex': 12,
        'currentCharOffset': 48,
        'lastReadAt': '2026-05-08T10:30:00.000Z',
      });
      _expectNoRawContentFields(options.data as Map);
      return _ok({'bookFingerprint': fingerprint});
    });
    final client = ReadingSyncApiClient(dio: _dio(adapter));

    await client.updateReadingProgress(
      bookFingerprint: fingerprint,
      currentChapterIndex: 3,
      currentParagraphIndex: 12,
      currentCharOffset: 48,
      lastReadAt: lastReadAt,
    );
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
}

ResponseBody _ok(Map<String, Object?> data) {
  return ResponseBody.fromString(
    jsonEncode({'success': true, 'data': data, 'error': null}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void _expectNoRawContentFields(Map<dynamic, dynamic> data) {
  for (final key in [
    'content',
    'chapterContent',
    'chapter_content',
    'originalFile',
    'original_file',
    'filePath',
    'file_path',
    'fullBook',
    'fullBookText',
    'paragraphText',
    'translatedText',
  ]) {
    expect(data, isNot(containsPair(key, anything)));
  }
}

class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handle);

  final ResponseBody Function(RequestOptions options) handle;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handle(options);
  }
}
