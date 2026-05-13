import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../data/auth_session_repository.dart';
import 'auth_form_shell.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    AuthSessionRepository? repository,
    VoidCallback? onAuthenticated,
  }) : _repository = repository,
       _onAuthenticated = onAuthenticated;

  final AuthSessionRepository? _repository;
  final VoidCallback? _onAuthenticated;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthSessionRepository _repository =
      widget._repository ?? AuthSessionRepository.secure();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: '登录',
      subtitle: '离线阅读，边读边学。',
      children: [
        TextField(
          key: const Key('sign-in-email-field'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: authInputDecoration(
            labelText: '邮箱',
            icon: Icons.alternate_email,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('sign-in-password-field'),
          controller: _passwordController,
          obscureText: true,
          decoration: authInputDecoration(
            labelText: '密码',
            icon: Icons.lock_outline,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('sign-in-submit-button'),
          style: authPrimaryButtonStyle(),
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? '正在登录...' : '继续'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting ? null : () => context.go('/register'),
          child: const Text('创建账号'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        widget._onAuthenticated?.call();
        context.go('/library');
      }
    } on ApiError catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '登录失败');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
