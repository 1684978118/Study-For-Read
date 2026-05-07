import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/auth/data/auth_api_client.dart';

void main() {
  test('login sends email and password to auth login endpoint', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/auth/login');
      expect(options.data, {
        'email': 'reader@example.com',
        'password': 'secret-password',
      });

      return _ok(_sessionJson());
    });
    final client = AuthApiClient(dio: _dio(adapter));

    final session = await client.login(
      email: 'reader@example.com',
      password: 'secret-password',
    );

    expect(session.user.email, 'reader@example.com');
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
  });

  test('register sends default language pair with user credentials', () async {
    final adapter = _FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/auth/register');
      expect(options.data, {
        'email': 'reader@example.com',
        'password': 'secret-password',
        'displayName': 'Reader',
        'sourceLang': 'ja',
        'targetLang': 'zh-CN',
      });

      return _ok(_sessionJson());
    });
    final client = AuthApiClient(dio: _dio(adapter));

    final session = await client.register(
      email: 'reader@example.com',
      password: 'secret-password',
      displayName: 'Reader',
    );

    expect(session.user.sourceLang, 'ja');
    expect(session.user.targetLang, 'zh-CN');
  });

  test('error envelope maps invalid credentials to stable api error', () async {
    final adapter = _FakeHttpAdapter(
      (options) => _json(401, {
        'success': false,
        'data': null,
        'error': {
          'code': 'AUTH_INVALID_CREDENTIALS',
          'message': 'Invalid email or password',
        },
      }),
    );
    final client = AuthApiClient(dio: _dio(adapter));

    await expectLater(
      client.login(email: 'reader@example.com', password: 'wrong-password'),
      throwsA(
        isA<ApiError>()
            .having((error) => error.code, 'code', 'AUTH_INVALID_CREDENTIALS')
            .having(
              (error) => error.message,
              'message',
              'Invalid email or password',
            ),
      ),
    );
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
}

Map<String, Object?> _sessionJson() {
  return {
    'user': {
      'id': 'user-id',
      'email': 'reader@example.com',
      'displayName': 'Reader',
      'sourceLang': 'ja',
      'targetLang': 'zh-CN',
      'status': 'active',
    },
    'accessToken': 'access-token',
    'refreshToken': 'refresh-token',
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
