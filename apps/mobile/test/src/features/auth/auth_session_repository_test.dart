import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/auth/data/auth_api_client.dart';
import 'package:study_for_read_mobile/src/features/auth/data/auth_session_repository.dart';
import 'package:study_for_read_mobile/src/features/auth/data/auth_token_store.dart';

void main() {
  test('login stores tokens through token store', () async {
    final tokenStore = _FakeTokenStore();
    final repository = AuthSessionRepository(
      apiClient: AuthApiClient(dio: _dio(_FakeHttpAdapter((_) => _session()))),
      tokenStore: tokenStore,
    );

    final session = await repository.login(
      email: 'reader@example.com',
      password: 'secret-password',
    );

    expect(session.accessToken, 'access-token');
    expect(tokenStore.accessToken, 'access-token');
    expect(tokenStore.refreshToken, 'refresh-token');
  });

  test('restore calls auth me when access token exists', () async {
    final tokenStore = _FakeTokenStore(
      accessToken: 'stored-access',
      refreshToken: 'stored-refresh',
    );
    late RequestOptions meRequest;
    final repository = AuthSessionRepository(
      apiClient: AuthApiClient(
        dio: _dio(_FakeHttpAdapter((options) {
          meRequest = options;
          return _ok({
            'id': 'user-id',
            'email': 'reader@example.com',
            'displayName': 'Reader',
            'sourceLang': 'ja',
            'targetLang': 'zh-CN',
            'status': 'active',
          });
        })),
      ),
      tokenStore: tokenStore,
    );

    final session = await repository.restore();

    expect(meRequest.method, 'GET');
    expect(meRequest.path, '/api/v1/auth/me');
    expect(meRequest.headers['Authorization'], 'Bearer stored-access');
    expect(session?.accessToken, 'stored-access');
    expect(session?.refreshToken, 'stored-refresh');
    expect(session?.user.email, 'reader@example.com');
  });

  test('restore returns null when no access token exists', () async {
    final repository = AuthSessionRepository(
      apiClient: AuthApiClient(
        dio: _dio(_FakeHttpAdapter((_) => fail('HTTP should not be called'))),
      ),
      tokenStore: _FakeTokenStore(),
    );

    expect(await repository.restore(), isNull);
  });

  test('sign out clears access and refresh tokens', () async {
    final tokenStore = _FakeTokenStore(
      accessToken: 'stored-access',
      refreshToken: 'stored-refresh',
    );
    final repository = AuthSessionRepository(
      apiClient: AuthApiClient(dio: _dio(_FakeHttpAdapter((_) => _session()))),
      tokenStore: tokenStore,
    );

    await repository.signOut();

    expect(tokenStore.accessToken, isNull);
    expect(tokenStore.refreshToken, isNull);
  });
}

class _FakeTokenStore implements AuthTokenStore {
  _FakeTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
}

ResponseBody _session() {
  return _ok({
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
  });
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
