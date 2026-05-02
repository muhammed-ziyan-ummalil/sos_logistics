abstract class DriverDetailState {}

class DriverDetailInitial extends DriverDetailState {}

class DriverDetailLoading extends DriverDetailState {}

class DriverDetailLoaded extends DriverDetailState {
  final Map<String, dynamic> driver;
  DriverDetailLoaded(this.driver);
}

class DriverDetailError extends DriverDetailState {
  final String message;
  DriverDetailError(this.message);
}

/// Emitted while an action (status change, assign, remove) is in flight.
/// Carries current driver so UI can keep rendering content behind the loader.
class DriverDetailActionLoading extends DriverDetailState {
  final Map<String, dynamic> driver;
  DriverDetailActionLoading(this.driver);
}

class DriverDetailActionSuccess extends DriverDetailState {
  final Map<String, dynamic> driver;
  final String message;
  DriverDetailActionSuccess({required this.driver, required this.message});
}

class DriverDetailActionError extends DriverDetailState {
  final Map<String, dynamic> driver;
  final String message;
  DriverDetailActionError({required this.driver, required this.message});
}
