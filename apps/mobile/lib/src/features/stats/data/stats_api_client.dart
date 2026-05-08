import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error.dart';
import '../domain/local_study_daily_stat.dart';

class StatsApiClient {
  StatsApiClient({Dio? dio, ApiClient? apiClient})
    : _dio = dio ?? apiClient?.dio ?? ApiClient().dio;

  final Dio _dio;

  Future<void> addDailyStats({
    required DateTime statDate,
    required int readingMinutes,
    required int lookupCount,
    required int paragraphTranslationCount,
    required int cardsCreated,
    required int cardsReviewed,
  }) async {
    final response = await _dio.request<Object?>(
      '/api/v1/stats/daily',
      data: {
        'statDate': LocalStudyDailyStat.dateString(statDate),
        'readingMinutes': readingMinutes,
        'lookupCount': lookupCount,
        'paragraphTranslationCount': paragraphTranslationCount,
        'cardsCreated': cardsCreated,
        'cardsReviewed': cardsReviewed,
      },
      options: Options(method: 'POST', validateStatus: (_) => true),
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
