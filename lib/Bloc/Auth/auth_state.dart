abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthNoSession extends AuthState {}

class AuthSessionRestored extends AuthState {
  final String token;
  final List<String> roles;
  final bool mustReset;
  final String selectedRole;
  final String? ownerStatus;
  final String? driverStatus;

  AuthSessionRestored({
    required this.token,
    required this.roles,
    required this.mustReset,
    required this.selectedRole,
    this.ownerStatus,
    this.driverStatus,
  });
}

class AuthSuccess extends AuthState {
  final String token;
  final List<String> roles;
  final bool mustReset;
  final String selectedRole;
  final String? ownerStatus;
  final String? driverStatus;

  AuthSuccess({
    required this.token,
    required this.roles,
    required this.mustReset,
    required this.selectedRole,
    this.ownerStatus,
    this.driverStatus,
  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthLoggedOut extends AuthState {}
