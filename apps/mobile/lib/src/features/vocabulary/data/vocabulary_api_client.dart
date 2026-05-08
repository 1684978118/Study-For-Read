import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error.dart';
import '../domain/vocabulary_card.dart';

class VocabularyApiClient {
  VocabularyApiClient({Dio? dio, ApiClient? apiClient})
    : _dio = dio ?? apiClient?.dio ?? ApiClient().dio;

  final Dio _dio;

  Future<VocabularyCardResult> createLexemeCard({
    required String lexemeId,
    String? sourceBookFingerprint,
    String? sourceBookTitle,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/vocabulary/cards',
      data: {
        'cardType': 'lexeme',
        'lexemeId': lexemeId,
        'sourceBookFingerprint': ?sourceBookFingerprint,
        'sourceBookTitle': ?sourceBookTitle,
      },
      allowExistingCardResult: true,
    );
    return VocabularyCardResult(
      card: VocabularyCard.fromJson(data),
      existing: data['_existing'] == true,
    );
  }

  Future<VocabularyCardResult> createPrivateSentenceCard({
    required String privateSurface,
    required String privateDefinition,
    String? privateContext,
    String? sourceBookFingerprint,
    String? sourceBookTitle,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/vocabulary/cards',
      data: {
        'cardType': 'private_sentence',
        'privateSurface': privateSurface,
        'privateDefinition': privateDefinition,
        'privateContext': ?privateContext,
        'sourceBookFingerprint': ?sourceBookFingerprint,
        'sourceBookTitle': ?sourceBookTitle,
      },
      allowExistingCardResult: true,
    );
    return VocabularyCardResult(
      card: VocabularyCard.fromJson(data),
      existing: data['_existing'] == true,
    );
  }

  Future<List<VocabularyCard>> listDueCards() async {
    final data = await _request('GET', '/api/v1/vocabulary/cards/due');
    final itemsJson = data['items'];
    if (itemsJson is! List) {
      throw const ApiError(
        code: 'INVALID_RESPONSE',
        message: 'Missing due vocabulary cards',
      );
    }
    return itemsJson
        .map(
          (item) =>
              VocabularyCard.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<VocabularyCard> reviewCard({
    required String cardId,
    required bool known,
    required DateTime reviewedAt,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/vocabulary/cards/$cardId/review',
      data: {
        'known': known,
        'reviewedAt': reviewedAt.toUtc().toIso8601String(),
      },
    );
    return VocabularyCard.fromJson(data);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? data,
    bool allowExistingCardResult = false,
  }) async {
    final response = await _dio.request<Object?>(
      path,
      data: data,
      options: Options(method: method, validateStatus: (_) => true),
    );

    final envelope = ApiEnvelope.fromJson(_decode(response.data));
    if (!envelope.success) {
      final error =
          envelope.error ??
          const ApiError(code: 'UNKNOWN_ERROR', message: 'Request failed');
      if (allowExistingCardResult && error.code == 'WORD_CARD_ALREADY_EXISTS') {
        final existing = _existingCardFrom(envelope.data);
        if (existing != null) {
          return {...existing, '_existing': true};
        }
      }
      throw _mapError(error);
    }

    final envelopeData = envelope.data;
    if (envelopeData == null) {
      throw const ApiError(
        code: 'INVALID_RESPONSE',
        message: 'Missing response data',
      );
    }
    return envelopeData;
  }

  Map<String, dynamic>? _existingCardFrom(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final existing = data['existing'];
    if (existing is Map) {
      return Map<String, dynamic>.from(existing);
    }
    final card = data['card'];
    if (card is Map) {
      return Map<String, dynamic>.from(card);
    }
    if (data['id'] is String) {
      return data;
    }
    return null;
  }

  ApiError _mapError(ApiError error) {
    return switch (error.code) {
      'WORD_CARD_ALREADY_EXISTS' => ApiError(
        code: 'VOCABULARY_CARD_ALREADY_EXISTS',
        message: error.message,
      ),
      'WORD_CARD_NOT_FOUND' => ApiError(
        code: 'VOCABULARY_CARD_NOT_FOUND',
        message: error.message,
      ),
      _ => error,
    };
  }

  Object? _decode(Object? data) {
    if (data is String) {
      return jsonDecode(data);
    }
    return data;
  }
}
