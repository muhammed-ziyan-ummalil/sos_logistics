abstract class OwnerVehiclesState {}

class OwnerVehiclesInitial extends OwnerVehiclesState {}

class OwnerVehiclesLoading extends OwnerVehiclesState {}

class OwnerVehiclesLoaded extends OwnerVehiclesState {
  final List<Map<String, dynamic>> vehicles;
  OwnerVehiclesLoaded(this.vehicles);
}

class OwnerVehiclesError extends OwnerVehiclesState {
  final String message;
  OwnerVehiclesError(this.message);
}
