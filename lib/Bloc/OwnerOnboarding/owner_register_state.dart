abstract class OwnerRegisterState {}

class OwnerRegisterInitial extends OwnerRegisterState {}

class OwnerRegisterLoading extends OwnerRegisterState {}

class OwnerRegisterSuccess extends OwnerRegisterState {}

class OwnerRegisterError extends OwnerRegisterState {
  final String message;
  OwnerRegisterError(this.message);
}
