import '../domain/app_user.dart';
import '../domain/auth_session.dart';
import 'auth_api_client.dart';
import 'auth_token_store.dart';

abstract interface class AuthSessionRepository {
  factory AuthSessionRepository({
    required AuthApiClient apiClient,
    required AuthTokenStore tokenStore,
  }) = DefaultAuthSessionRepository;

  factory AuthSessionRepository.secure() {
    return AuthSessionRepository(
      apiClient: AuthApiClient(),
      tokenStore: SecureAuthTokenStore(),
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthSession?> restore();

  Future<AuthSession> refresh();

  Future<AppUser> me();

  Future<void> signOut();
}

class DefaultAuthSessionRepository implements AuthSessionRepository {
  DefaultAuthSessionRepository({
    required AuthApiClient apiClient,
    required AuthTokenStore tokenStore,
  })  : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final AuthApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.login(email: email, password: password);
    await _tokenStore.writeTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final session = await _apiClient.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _tokenStore.writeTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<AuthSession?> restore() async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final user = await _apiClient.me(accessToken: accessToken);
    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<AuthSession> refresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Missing refresh token');
    }

    final tokens = await _apiClient.refresh(refreshToken: refreshToken);
    await _tokenStore.writeTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    final user = await _apiClient.me(accessToken: tokens.accessToken);
    return AuthSession(
      user: user,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  @override
  Future<AppUser> me() async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Missing access token');
    }
    return _apiClient.me(accessToken: accessToken);
  }

  @override
  Future<void> signOut() {
    return _tokenStore.clearTokens();
  }
}
