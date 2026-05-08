import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/stats/data/stats_api_client.dart';

void main() {
  test('addDailyStats posts incremental counters only', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/stats/daily');
      expect(options.data, {
        'statDate': '2026-05-08',
        'readingMinutes': 12,
        'lookupCount': 8,
        'paragraphTranslationCount': 3,
        'cardsCreated': 2,
        'cardsReviewed': 5,
      });
      expect(options.data, isNot(containsPair('content', anything)));
      expect(options.data, isNot(containsPair('rawText', anything)));
      expect(options.data, isNot(containsPair('translatedText', anything)));
      return _ok({'statDate': '2026-05-08'});
    });
    final client = StatsApiClient(dio: _dio(adapter));

    await client.addDailyStats(
      statDate: DateTime.utc(2026, 5, 8),
      readingMinutes: 12,
      lookupCount: 8,
      paragraphTranslationCount: 3,
      cardsCreated: 2,
      cardsReviewed: 5,
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
