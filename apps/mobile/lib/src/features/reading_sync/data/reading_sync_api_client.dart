import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error.dart';

class ReadingSyncApiClient {
  ReadingSyncApiClient({Dio? dio, ApiClient? apiClient})
    : _dio = dio ?? apiClient?.dio ?? ApiClient().dio;

  final Dio _dio;

  Future<void> upsertBookMetadata({
    required String bookFingerprint,
    required String title,
    String? author,
    required String fileType,
    required String sourceLang,
    required String targetLang,
    required int chapterCount,
  }) {
    final requestData = <String, Object?>{
      'title': title,
      'fileType': fileType,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'chapterCount': chapterCount,
    };
    if (author != null) {
      requestData['author'] = author;
    }
    return _request(
      'PUT',
      '/api/v1/reading/books/$bookFingerprint',
      data: requestData,
    );
  }

  Future<void> updateReadingProgress({
    required String bookFingerprint,
    required int currentChapterIndex,
    required int currentParagraphIndex,
    required int currentCharOffset,
    DateTime? lastReadAt,
  }) {
    final requestData = <String, Object?>{
      'currentChapterIndex': currentChapterIndex,
      'currentParagraphIndex': currentParagraphIndex,
      'currentCharOffset': currentCharOffset,
    };
    if (lastReadAt != null) {
      requestData['lastReadAt'] = lastReadAt.toUtc().toIso8601String();
    }
    return _request(
      'PATCH',
      '/api/v1/reading/books/$bookFingerprint/progress',
      data: requestData,
    );
  }

  Future<void> _request(
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
      throw envelope.error ??
          const ApiError(code: 'UNKNOWN_ERROR', message: 'Request failed');
    }
  }

  Object? _decode(Object? data) {
    if (data is String) {
      return jsonDecode(data);
    }
    return data;
  }
}
