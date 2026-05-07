import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/auth/data/auth_session_repository.dart';
import 'package:study_for_read_mobile/src/features/auth/domain/app_user.dart';
import 'package:study_for_read_mobile/src/features/auth/domain/auth_session.dart';
import 'package:study_for_read_mobile/src/features/auth/presentation/sign_in_screen.dart';

void main() {
  testWidgets('Sign In screen shows inline error on invalid credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(repository: _FailingAuthSessionRepository()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('sign-in-email-field')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password-field')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });
}

class _FailingAuthSessionRepository implements AuthSessionRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    throw const ApiError(
      code: 'AUTH_INVALID_CREDENTIALS',
      message: 'Invalid email or password',
    );
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restore() async => null;

  @override
  Future<AuthSession> refresh() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> me() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}
