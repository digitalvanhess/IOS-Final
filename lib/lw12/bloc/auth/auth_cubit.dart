import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

/// Authentication state machine:
///
/// ```
/// AuthInitial ──login()──▶ AuthLoading ──(delay)──▶ AuthSuccess
///      ▲                        ▲                └──▶ AuthError
///      └──────logout()──────────┴── login() again from AuthError
/// ```
///
/// A Cubit, not a Bloc: the UI calls methods (`login`, `logout`) instead of
/// adding events, because there is one simple flow and no need for event
/// transformers.
class AuthCubit extends Cubit<AuthState> {
  /// Demo account from the lab spec.
  static const demoEmail = 'student@narxoz.kz';
  static const demoPassword = '123456';
  static const demoUsername = 'Студент Narxoz';

  /// Fake "server" round trip. Tests pass [Duration.zero].
  final Duration delay;

  AuthCubit({this.delay = const Duration(seconds: 2)})
    : super(const AuthInitial());

  Future<void> login(String email, String password) async {
    // Ignore double taps while a request is already running.
    if (state is AuthLoading) return;

    emit(const AuthLoading());
    await Future<void>.delayed(delay);
    // The screen may have been closed during the delay.
    if (isClosed) return;

    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      emit(const AuthError('Введите email и пароль'));
    } else if (!_emailPattern.hasMatch(cleanEmail)) {
      emit(const AuthError('Некорректный email'));
    } else if (password.length < 6) {
      emit(const AuthError('Пароль должен быть не короче 6 символов'));
    } else if (cleanEmail != demoEmail || password != demoPassword) {
      emit(const AuthError('Неверный email или пароль'));
    } else {
      emit(const AuthSuccess(username: demoUsername, email: demoEmail));
    }
  }

  void logout() => emit(const AuthInitial());

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
