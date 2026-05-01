import 'package:equatable/equatable.dart';

abstract class OwnerAuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OwnerAuthInitial extends OwnerAuthState {}
class OwnerAuthLoading extends OwnerAuthState {}

class OwnerAuthSuccess extends OwnerAuthState {
  final String token;
  OwnerAuthSuccess(this.token);
  @override
  List<Object?> get props => [token];
}

class OwnerAuthError extends OwnerAuthState {
  final String message;
  OwnerAuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class OwnerLoggedOut extends OwnerAuthState {}
