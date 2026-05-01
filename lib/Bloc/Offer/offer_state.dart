import 'package:equatable/equatable.dart';
import '../../Model/delivery_model.dart';

abstract class OfferState extends Equatable {
  @override List<Object?> get props => [];
}

class OfferInitial     extends OfferState {}
class OfferLoading     extends OfferState {}
class OfferNone        extends OfferState {}
class OfferAvailable   extends OfferState {
  final DeliveryOffer offer;
  const OfferAvailable(this.offer);
  @override List<Object?> get props => [offer];
}
class OfferAccepted    extends OfferState {
  final int deliveryId;
  const OfferAccepted(this.deliveryId);
  @override List<Object?> get props => [deliveryId];
}
class OfferRejected    extends OfferState {}
class OfferError       extends OfferState {
  final String message;
  const OfferError(this.message);
  @override List<Object?> get props => [message];
}
