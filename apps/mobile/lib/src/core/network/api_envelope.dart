import 'api_error.dart';

class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });

  final bool success;
  final T? data;
  final ApiError? error;

  static ApiEnvelope<Map<String, dynamic>> fromJson(Object? json) {
    if (json is! Map) {
      throw const ApiError(
        code: 'INVALID_RESPONSE',
        message: 'Invalid API response',
      );
    }

    final map = Map<String, dynamic>.from(json);
    final errorJson = map['error'];

    return ApiEnvelope<Map<String, dynamic>>(
      success: map['success'] == true,
      data: map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
      error: errorJson is Map
          ? ApiError(
              code: errorJson['code'] as String? ?? 'UNKNOWN_ERROR',
              message: errorJson['message'] as String? ?? 'Request failed',
            )
          : null,
    );
  }
}
