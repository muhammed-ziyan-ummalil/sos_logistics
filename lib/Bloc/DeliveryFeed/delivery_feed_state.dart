import '../../Model/delivery_request_model.dart';

abstract class DeliveryFeedState {}

class DeliveryFeedInitial extends DeliveryFeedState {}

class DeliveryFeedLoading extends DeliveryFeedState {}

class DeliveryFeedLoaded extends DeliveryFeedState {
  final List<DeliveryRequestModel> requests;
  DeliveryFeedLoaded(this.requests);
}

class DeliveryFeedError extends DeliveryFeedState {
  final String message;
  DeliveryFeedError(this.message);
}
