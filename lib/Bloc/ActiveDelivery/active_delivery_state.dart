import 'package:equatable/equatable.dart';
import '../../Model/delivery_model.dart';

abstract class ActiveDeliveryState extends Equatable {
  @override List<Object?> get props => [];
}

class ActiveDeliveryInitial   extends ActiveDeliveryState {}
class ActiveDeliveryLoading   extends ActiveDeliveryState {}
class ActiveDeliveryNone      extends ActiveDeliveryState {}
class ActiveDeliveryLoaded    extends ActiveDeliveryState {
  final ActiveDelivery delivery;
  const ActiveDeliveryLoaded(this.delivery);
  @override List<Object?> get props => [delivery];
}
class ActiveDeliveryCompleted extends ActiveDeliveryState {}
class ActiveDeliveryOtpError  extends ActiveDeliveryState {
  final String message;
  final bool   isDispute;
  const ActiveDeliveryOtpError(this.message, {this.isDispute = false});
  @override List<Object?> get props => [message, isDispute];
}
class ActiveDeliveryError     extends ActiveDeliveryState {
  final String message;
  const ActiveDeliveryError(this.message);
  @override List<Object?> get props => [message];
}
