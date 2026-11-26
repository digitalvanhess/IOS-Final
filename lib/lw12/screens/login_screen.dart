import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';
import 'shop_catalog_screen.dart';

/// Screen 1 (LW12): login form driven by [AuthCubit].
///
/// One [BlocConsumer] with two clearly separated jobs:
/// * `listener` runs ONCE per new state, for side effects: red SnackBar on
///   [AuthError], navigation on [AuthSuccess]. Never builds widgets.
/// * `builder` may run many times and only returns widgets: the button, or
///   a spinner while [AuthLoading].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
      _emailController.text,
      _passwordController.text,
    );
  }

  void _onAuthChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthError(:final message):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.danger,
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
      case AuthSuccess():
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Replace the login route: «Назад» from the catalog goes to
        // Профиль, not back to the form.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ShopCatalogScreen()),
        );
      case AuthInitial() || AuthLoading():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<AuthCubit, AuthState>(
                // Only errors and success need a side effect.
                listenWhen: (_, current) =>
                    current is AuthError || current is AuthSuccess,
                listener: _onAuthChanged,
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      const SizedBox(height: 32),
                      TextField(
                        key: const ValueKey('login_email'),
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: _decoration(
                          label: 'Email',
                          icon: Icons.alternate_email,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('login_password'),
                        controller: _passwordController,
                        enabled: !isLoading,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: _decoration(
                          label: 'Пароль',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            tooltip: _obscure
                                ? 'Показать пароль'
                                : 'Скрыть пароль',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: context.palette.accentText,
                                ),
                              )
                            : ElevatedButton(
                                key: const ValueKey('login_button'),
                                onPressed: _submit,
                                child: const Text('Войти'),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Демо: ${AuthCubit.demoEmail} / ${AuthCubit.demoPassword}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    const radius = BorderRadius.all(Radius.circular(16));
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.palette.card,
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: context.palette.accent),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: context.palette.accentSoft,
          child: Icon(
            Icons.storefront,
            size: 34,
            color: context.palette.accentText,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Студенческий магазин',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          'Войдите, чтобы собрать корзину со стипендии',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textSecondary),
        ),
      ],
    );
  }
}
