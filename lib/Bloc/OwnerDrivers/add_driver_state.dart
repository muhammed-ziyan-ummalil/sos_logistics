abstract class AddDriverState {}

class AddDriverInitial extends AddDriverState {}

class AddDriverLoading extends AddDriverState {}

class AddDriverSuccess extends AddDriverState {
  final String driverId;
  final String tempPassword;
  AddDriverSuccess({required this.driverId, required this.tempPassword});
}

class AddDriverError extends AddDriverState {
  final String message;
  AddDriverError(this.message);
}
