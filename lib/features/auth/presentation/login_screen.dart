import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/max_width.dart';
import '../domain/auth_repository.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Выполняет запрос: блокирует кнопки, показывает ошибку репозитория.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      // При успехе экран уже заменён роутером.
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validate({required bool withPassword}) {
    final email = _email.text.trim();
    final emailError = email.contains('@') ? null : 'Неверный email';
    final passwordError = !withPassword || _password.text.length >= 6
        ? null
        : 'Пароль — минимум 6 символов';
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    return emailError == null && passwordError == null;
  }

  void _submit() {
    if (!_validate(withPassword: true)) return;
    final auth = ref.read(authProvider.notifier);
    final email = _email.text.trim();
    _run(
      () => _registering
          ? auth.register(email, _password.text)
          : auth.signInWithEmail(email, _password.text),
    );
  }

  void _reset() {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Введите email';
        _passwordError = null;
      });
      return;
    }
    setState(() => _emailError = null);
    _run(() async {
      await ref.read(authProvider.notifier).resetPassword(email);
      if (!mounted) return;
      setState(() => _info = 'Письмо для сброса пароля отправлено');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.read(authProvider.notifier);
    final idle = !_busy;

    return Scaffold(
      body: SafeArea(
        child: MaxWidth(
          width: 420,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Fitness Planner',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Записывайте подходы и смотрите, что делали в прошлый раз',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: [
                  _registering
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  errorText: _passwordError,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              if (_info != null) ...[const SizedBox(height: 12), Text(_info!)],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: idle ? _submit : null,
                child: Text(_registering ? 'Создать аккаунт' : 'Войти'),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              TextButton(
                onPressed: idle
                    ? () => setState(() => _registering = !_registering)
                    : null,
                child: Text(
                  _registering
                      ? 'Уже есть аккаунт? Войти'
                      : 'Нет аккаунта? Зарегистрироваться',
                ),
              ),
              TextButton(
                onPressed: idle ? _reset : null,
                child: const Text('Забыли пароль?'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: idle ? () => _run(auth.signInWithGoogle) : null,
                child: const Text('Войти через Google'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: idle ? () => _run(auth.continueAsGuest) : null,
                child: const Text('Продолжить как гость'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
