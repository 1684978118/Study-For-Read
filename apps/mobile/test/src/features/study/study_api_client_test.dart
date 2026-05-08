import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/study/data/study_api_client.dart';

void main() {
  test('lookup sends text, language pair, and context', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/study/lookup');
      expect(options.data, {
        'text': '心',
        'sourceLang': 'ja',
        'targetLang': 'zh-CN',
        'context': '先生の心',
      });

      return _ok({
        'kind': 'lexeme',
        'lexeme': {
          'id': 'lexeme-1',
          'surface': '心',
          'reading': 'こころ',
          'entryType': 'word',
          'partOfSpeech': 'noun',
          'definition': 'heart; mind',
          'shortDefinition': 'heart',
        },
        'provider': 'public_lexeme',
        'providerMessage': null,
      });
    });
    final client = StudyApiClient(dio: _dio(adapter));

    final result = await client.lookup(
      text: '心',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      context: '先生の心',
    );

    expect(result.kind, 'lexeme');
    expect(result.provider, 'public_lexeme');
    expect(result.providerMessage, isNull);
    expect(result.lexeme.id, 'lexeme-1');
    expect(result.lexeme.surface, '心');
    expect(result.lexeme.reading, 'こころ');
    expect(result.lexeme.entryType, 'word');
    expect(result.lexeme.partOfSpeech, 'noun');
    expect(result.lexeme.definition, 'heart; mind');
    expect(result.lexeme.shortDefinition, 'heart');
  });

  test('lookup omits null context from request body', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.path, '/api/v1/study/lookup');
      expect(options.data, isNot(containsPair('context', anything)));

      return _ok({
        'kind': 'provider',
        'lexeme': {
          'id': 'lookup-1',
          'surface': '長い',
          'reading': 'ながい',
          'entryType': 'word',
          'partOfSpeech': 'adjective',
          'definition': 'long',
          'shortDefinition': null,
        },
        'provider': 'local_fallback',
        'providerMessage': 'placeholder',
      });
    });
    final client = StudyApiClient(dio: _dio(adapter));

    final result = await client.lookup(
      text: '長い',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    );

    expect(result.providerMessage, 'placeholder');
    expect(result.lexeme.shortDefinition, isNull);
  });

  test('paragraph translation sends exactly one selected paragraph string', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/study/translate-paragraph');
      expect(options.data, {
        'text': '私はその人を常に先生と呼んでいた。',
        'sourceLang': 'ja',
        'targetLang': 'zh-CN',
      });
      expect(options.data['text'], isA<String>());
      expect(options.data['text'], isNot(isA<List<Object?>>()));
      expect(options.data, isNot(containsPair('chapterContent', anything)));
      expect(options.data, isNot(containsPair('bookContent', anything)));

      return _ok({
        'translatedText': '我一直称那个人为先生。',
        'provider': 'configured_provider',
        'cached': false,
        'message': null,
      });
    });
    final client = StudyApiClient(dio: _dio(adapter));

    final result = await client.translateParagraph(
      text: '私はその人を常に先生と呼んでいた。',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    );

    expect(result.translatedText, '我一直称那个人为先生。');
    expect(result.provider, 'configured_provider');
    expect(result.cached, isFalse);
    expect(result.message, isNull);
  });

  test('annotate sends source text and parses token fields', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/study/annotate');
      expect(options.data, {'text': '先生の心', 'sourceLang': 'ja'});

      return _ok({
        'tokens': [
          {
            'text': '先生',
            'reading': 'せんせい',
            'dictionaryForm': '先生',
            'partOfSpeech': 'noun',
          },
          {
            'text': 'の',
            'reading': null,
            'dictionaryForm': 'の',
            'partOfSpeech': 'particle',
          },
        ],
      });
    });
    final client = StudyApiClient(dio: _dio(adapter));

    final tokens = await client.annotate(text: '先生の心', sourceLang: 'ja');

    expect(tokens, hasLength(2));
    expect(tokens.first.text, '先生');
    expect(tokens.first.reading, 'せんせい');
    expect(tokens.first.dictionaryForm, '先生');
    expect(tokens.first.partOfSpeech, 'noun');
    expect(tokens.last.reading, isNull);
  });

  test('unsupported language pair maps to stable mobile error', () async {
    final adapter = _FakeHttpAdapter(
      (options) => _json(400, {
        'success': false,
        'data': null,
        'error': {
          'code': 'TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR',
          'message': 'Unsupported language pair',
        },
      }),
    );
    final client = StudyApiClient(dio: _dio(adapter));

    await expectLater(
      client.lookup(text: '心', sourceLang: 'en', targetLang: 'zh-CN'),
      throwsA(
        isA<ApiError>().having(
          (error) => error.code,
          'code',
          'STUDY_UNSUPPORTED_LANGUAGE_PAIR',
        ),
      ),
    );
  });

  test('provider unavailable maps to stable mobile error', () async {
    final adapter = _FakeHttpAdapter(
      (options) => _json(503, {
        'success': false,
        'data': null,
        'error': {
          'code': 'TRANSLATION_PROVIDER_UNAVAILABLE',
          'message': 'Provider unavailable',
        },
      }),
    );
    final client = StudyApiClient(dio: _dio(adapter));

    await expectLater(
      client.translateParagraph(
        text: '短い段落',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
      ),
      throwsA(
        isA<ApiError>().having(
          (error) => error.code,
          'code',
          'STUDY_PROVIDER_UNAVAILABLE',
        ),
      ),
    );
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
}

ResponseBody _ok(Map<String, Object?> data) {
  return _json(200, {'success': true, 'data': data, 'error': null});
}

ResponseBody _json(int statusCode, Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
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
