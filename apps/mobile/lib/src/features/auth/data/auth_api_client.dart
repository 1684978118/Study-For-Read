import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';

class AuthApiClient {
  AuthApiClient({Dio? dio, ApiClient? apiClient})
      : _dio = dio ?? apiClient?.dio ?? ApiClient().dio;

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/register',
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'sourceLang': 'ja',
        'targetLang': 'zh-CN',
      },
    );
    return AuthSession.fromJson(data);
  }

  Future<AuthTokens> refresh({required String refreshToken}) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthTokens.fromJson(data);
  }

  Future<AppUser> me({required String accessToken}) async {
    final data = await _request(
      'GET',
      '/api/v1/auth/me',
      accessToken: accessToken,
    );
    return AppUser.fromJson(data);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? data,
    String? accessToken,
  }) async {
    final response = await _dio.request<Object?>(
      path,
      data: data,
      options: Options(
        method: method,
        validateStatus: (_) => true,
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    final envelope = ApiEnvelope.fromJson(_decode(response.data));
    if (!envelope.success) {
      throw envelope.error ??
          const ApiError(code: 'UNKNOWN_ERROR', message: 'Request failed');
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

  Object? _decode(Object? data) {
    if (data is String) {
      return jsonDecode(data);
    }
    return data;
  }
}
