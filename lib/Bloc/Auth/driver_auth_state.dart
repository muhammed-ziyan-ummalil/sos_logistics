import 'package:equatable/equatable.dart';

abstract class DriverAuthState extends Equatable {
  @override List<Object?> get props => [];
}

class DriverAuthInitial    extends DriverAuthState {}
class DriverAuthLoading    extends DriverAuthState {}
class DriverAuthSuccess    extends DriverAuthState {
  final String token;
  DriverAuthSuccess(this.token);
  @override List<Object?> get props => [token];
}
class DriverAuthError      extends DriverAuthState {
  final String message;
  DriverAuthError(this.message);
  @override List<Object?> get props => [message];
}
class DriverLoggedOut      extends DriverAuthState {}
class DriverSplashChecked  extends DriverAuthState {
  final bool isLoggedIn;
  DriverSplashChecked(this.isLoggedIn);
  @override List<Object?> get props => [isLoggedIn];
}
