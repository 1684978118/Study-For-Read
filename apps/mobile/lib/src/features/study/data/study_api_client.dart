import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error.dart';
import '../domain/annotation_token.dart';
import '../domain/lookup_result.dart';
import '../domain/translation_result.dart';

class StudyApiClient {
  StudyApiClient({Dio? dio, ApiClient? apiClient})
    : _dio = dio ?? apiClient?.dio ?? ApiClient().dio;

  final Dio _dio;

  Future<LookupResult> lookup({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? context,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/study/lookup',
      data: {
        'text': text,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'context': ?context,
      },
    );
    return LookupResult.fromJson(data);
  }

  Future<TranslationResult> translateParagraph({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/study/translate-paragraph',
      data: {
        'text': text,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      },
    );
    return TranslationResult.fromJson(data);
  }

  Future<List<AnnotationToken>> annotate({
    required String text,
    required String sourceLang,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/study/annotate',
      data: {'text': text, 'sourceLang': sourceLang},
    );
    final tokensJson = data['tokens'];
    if (tokensJson is! List) {
      throw const ApiError(
        code: 'INVALID_RESPONSE',
        message: 'Missing annotation tokens',
      );
    }
    return tokensJson
        .map(
          (token) =>
              AnnotationToken.fromJson(Map<String, dynamic>.from(token as Map)),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    required Map<String, Object?> data,
  }) async {
    final response = await _dio.request<Object?>(
      path,
      data: data,
      options: Options(method: method, validateStatus: (_) => true),
    );

    final envelope = ApiEnvelope.fromJson(_decode(response.data));
    if (!envelope.success) {
      throw _mapError(
        envelope.error ??
            const ApiError(code: 'UNKNOWN_ERROR', message: 'Request failed'),
      );
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

  ApiError _mapError(ApiError error) {
    return switch (error.code) {
      'TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR' => ApiError(
        code: 'STUDY_UNSUPPORTED_LANGUAGE_PAIR',
        message: error.message,
      ),
      'TRANSLATION_PROVIDER_UNAVAILABLE' => ApiError(
        code: 'STUDY_PROVIDER_UNAVAILABLE',
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
