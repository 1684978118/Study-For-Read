import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../data/auth_session_repository.dart';
import 'auth_form_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    AuthSessionRepository? repository,
    VoidCallback? onAuthenticated,
  }) : _repository = repository,
       _onAuthenticated = onAuthenticated;

  final AuthSessionRepository? _repository;
  final VoidCallback? _onAuthenticated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  late final AuthSessionRepository _repository =
      widget._repository ?? AuthSessionRepository.secure();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: 'Register',
      subtitle: 'Create your reading profile.',
      children: [
        TextField(
          key: const Key('register-email-field'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: authInputDecoration(
            labelText: 'Email',
            icon: Icons.alternate_email,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('register-display-name-field'),
          controller: _displayNameController,
          decoration: authInputDecoration(
            labelText: 'Display name',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('register-password-field'),
          controller: _passwordController,
          obscureText: true,
          decoration: authInputDecoration(
            labelText: 'Password',
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
          key: const Key('register-submit-button'),
          style: authPrimaryButtonStyle(),
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Creating...' : 'Create profile'),
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
      await _repository.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
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
        setState(() => _errorMessage = 'Registration failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
