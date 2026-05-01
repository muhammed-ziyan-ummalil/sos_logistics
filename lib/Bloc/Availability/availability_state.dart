import 'package:equatable/equatable.dart';

abstract class AvailabilityState extends Equatable {
  @override List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {}
class AvailabilityLoading extends AvailabilityState {}
class AvailabilityUpdated extends AvailabilityState {
  final bool isOnline;
  AvailabilityUpdated(this.isOnline);
  @override List<Object?> get props => [isOnline];
}
class AvailabilityError extends AvailabilityState {
  final String message;
  AvailabilityError(this.message);
  @override List<Object?> get props => [message];
}
