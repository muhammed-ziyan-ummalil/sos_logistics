abstract class OwnerProfileState {}

class OwnerProfileInitial extends OwnerProfileState {}

class OwnerProfileLoading extends OwnerProfileState {}

class OwnerProfileLoaded extends OwnerProfileState {
  final Map<String, dynamic> data;
  OwnerProfileLoaded(this.data);
}

class OwnerProfileUpdating extends OwnerProfileState {
  final Map<String, dynamic> data;
  OwnerProfileUpdating(this.data);
}

class OwnerProfileUpdated extends OwnerProfileState {
  final Map<String, dynamic> data;
  OwnerProfileUpdated(this.data);
}

class OwnerProfileError extends OwnerProfileState {
  final String message;
  OwnerProfileError(this.message);
}
