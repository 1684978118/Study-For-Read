import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/vocabulary_api_client.dart';

void main() {
  test('createLexemeCard sends lexeme payload and parses card', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/vocabulary/cards');
      expect(options.data, {
        'cardType': 'lexeme',
        'lexemeId': 'lexeme-1',
        'sourceBookFingerprint':
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'sourceBookTitle': 'Kokoro',
      });
      _expectNoRawContentFields(options.data as Map);

      return _ok(_lexemeCardJson(id: 'card-1'));
    });
    final client = VocabularyApiClient(dio: _dio(adapter));

    final result = await client.createLexemeCard(
      lexemeId: 'lexeme-1',
      sourceBookFingerprint:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      sourceBookTitle: 'Kokoro',
    );

    expect(result.card.id, 'card-1');
    expect(result.card.cardType, 'lexeme');
    expect(result.card.lexeme?.id, 'lexeme-1');
    expect(result.card.surface, '心');
    expect(result.card.reviewStatus, 'new');
    expect(result.existing, isFalse);
  });

  test(
    'createPrivateSentenceCard sends private sentence payload only',
    () async {
      final adapter = _FakeHttpAdapter((options) {
        expect(options.method, 'POST');
        expect(options.path, '/api/v1/vocabulary/cards');
        expect(options.data, {
          'cardType': 'private_sentence',
          'privateSurface': '私は先生と呼んでいた。',
          'privateDefinition': '我一直称那个人为先生。',
          'privateContext': '短い私有上下文',
          'sourceBookFingerprint':
              '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
          'sourceBookTitle': 'Kokoro',
        });
        _expectNoRawContentFields(options.data as Map);

        return _ok(_privateSentenceCardJson());
      });
      final client = VocabularyApiClient(dio: _dio(adapter));

      final result = await client.createPrivateSentenceCard(
        privateSurface: '私は先生と呼んでいた。',
        privateDefinition: '我一直称那个人为先生。',
        privateContext: '短い私有上下文',
        sourceBookFingerprint:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        sourceBookTitle: 'Kokoro',
      );

      expect(result.card.cardType, 'private_sentence');
      expect(result.card.surface, '私は先生と呼んでいた。');
      expect(result.card.definition, '我一直称那个人为先生。');
    },
  );

  test('listDueCards calls due endpoint and parses items', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/api/v1/vocabulary/cards/due');
      expect(options.data, isNull);

      return _ok({
        'items': [
          {
            'id': 'card-1',
            'cardType': 'lexeme',
            'surface': '心',
            'reading': 'こころ',
            'definition': 'heart; mind',
            'reviewStatus': 'new',
            'reviewCount': 0,
            'nextReviewAt': null,
          },
        ],
      });
    });
    final client = VocabularyApiClient(dio: _dio(adapter));

    final cards = await client.listDueCards();

    expect(cards, hasLength(1));
    expect(cards.single.id, 'card-1');
    expect(cards.single.surface, '心');
    expect(cards.single.reading, 'こころ');
    expect(cards.single.definition, 'heart; mind');
  });

  test('reviewCard sends known and reviewedAt', () async {
    final reviewedAt = DateTime.utc(2026, 5, 8, 10, 30);
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/vocabulary/cards/card-1/review');
      expect(options.data, {
        'known': true,
        'reviewedAt': '2026-05-08T10:30:00.000Z',
      });

      return _ok({
        'id': 'card-1',
        'reviewStatus': 'learning',
        'reviewCount': 1,
        'nextReviewAt': '2026-05-09T10:30:00.000Z',
        'lastReviewedAt': '2026-05-08T10:30:00.000Z',
      });
    });
    final client = VocabularyApiClient(dio: _dio(adapter));

    final card = await client.reviewCard(
      cardId: 'card-1',
      known: true,
      reviewedAt: reviewedAt,
    );

    expect(card.id, 'card-1');
    expect(card.reviewStatus, 'learning');
    expect(card.reviewCount, 1);
    expect(card.nextReviewAt, DateTime.utc(2026, 5, 9, 10, 30));
    expect(card.lastReviewedAt, reviewedAt);
  });

  test(
    'already exists with existing card data returns idempotent result',
    () async {
      final adapter = _FakeHttpAdapter(
        (options) => _json(409, {
          'success': false,
          'data': {'existing': _lexemeCardJson(id: 'existing-card')},
          'error': {
            'code': 'WORD_CARD_ALREADY_EXISTS',
            'message': 'Already exists',
          },
        }),
      );
      final client = VocabularyApiClient(dio: _dio(adapter));

      final result = await client.createLexemeCard(lexemeId: 'lexeme-1');

      expect(result.existing, isTrue);
      expect(result.card.id, 'existing-card');
    },
  );

  test(
    'already exists without card data maps to stable mobile error',
    () async {
      final adapter = _FakeHttpAdapter(
        (options) => _json(409, {
          'success': false,
          'data': null,
          'error': {
            'code': 'WORD_CARD_ALREADY_EXISTS',
            'message': 'Already exists',
          },
        }),
      );
      final client = VocabularyApiClient(dio: _dio(adapter));

      await expectLater(
        client.createLexemeCard(lexemeId: 'lexeme-1'),
        throwsA(
          isA<ApiError>().having(
            (error) => error.code,
            'code',
            'VOCABULARY_CARD_ALREADY_EXISTS',
          ),
        ),
      );
    },
  );

  test('word card not found maps to stable mobile error', () async {
    final adapter = _FakeHttpAdapter(
      (options) => _json(404, {
        'success': false,
        'data': null,
        'error': {'code': 'WORD_CARD_NOT_FOUND', 'message': 'Card not found'},
      }),
    );
    final client = VocabularyApiClient(dio: _dio(adapter));

    await expectLater(
      client.reviewCard(
        cardId: 'missing-card',
        known: false,
        reviewedAt: DateTime.utc(2026, 5, 8),
      ),
      throwsA(
        isA<ApiError>().having(
          (error) => error.code,
          'code',
          'VOCABULARY_CARD_NOT_FOUND',
        ),
      ),
    );
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
}

Map<String, Object?> _lexemeCardJson({required String id}) {
  return {
    'id': id,
    'cardType': 'lexeme',
    'lexeme': {
      'id': 'lexeme-1',
      'surface': '心',
      'reading': 'こころ',
      'definition': 'heart; mind',
    },
    'reviewStatus': 'new',
    'reviewCount': 0,
    'nextReviewAt': null,
  };
}

Map<String, Object?> _privateSentenceCardJson() {
  return {
    'id': 'private-card-1',
    'cardType': 'private_sentence',
    'surface': '私は先生と呼んでいた。',
    'reading': null,
    'definition': '我一直称那个人为先生。',
    'reviewStatus': 'new',
    'reviewCount': 0,
    'nextReviewAt': null,
  };
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

void _expectNoRawContentFields(Map<dynamic, dynamic> data) {
  for (final key in [
    'content',
    'chapterContent',
    'chapter_content',
    'originalFile',
    'original_file',
    'filePath',
    'file_path',
    'fullBookText',
    'bookContent',
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
