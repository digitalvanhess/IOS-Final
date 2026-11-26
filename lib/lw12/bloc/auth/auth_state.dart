part of 'auth_cubit.dart';

/// Every state is immutable (`final` fields, `const` constructors) and
/// extends [Equatable]. Equatable compares states by [props], so
/// `AuthError('x') == AuthError('x')` and the Cubit does not emit (and the
/// UI does not rebuild) when the new state equals the current one.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Nobody has tried to log in yet (or the user logged out).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Credentials are being checked: the button turns into a spinner.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Logged in. The listener navigates to the catalog.
final class AuthSuccess extends AuthState {
  final String username;
  final String email;

  const AuthSuccess({required this.username, required this.email});

  @override
  List<Object?> get props => [username, email];
}

/// Login failed. The listener shows a red SnackBar with [message].
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
