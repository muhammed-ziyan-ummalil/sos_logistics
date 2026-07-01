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
  ActiveDeliveryLoaded(this.delivery);
  @override List<Object?> get props => [delivery];
}
class ActiveDeliveryCompleted extends ActiveDeliveryState {}
class ActiveDeliveryOtpReady  extends ActiveDeliveryState {
  final bool isPickup;
  // TODO(TESTING): plaintext OTP for in-app display until SMS/email is live.
  final String? testOtp;
  ActiveDeliveryOtpReady({required this.isPickup, this.testOtp});
  @override List<Object?> get props => [isPickup, testOtp];
}
class ActiveDeliveryOtpError  extends ActiveDeliveryState {
  final String message;
  final bool   isDispute;
  ActiveDeliveryOtpError(this.message, {this.isDispute = false});
  @override List<Object?> get props => [message, isDispute];
}
class ActiveDeliveryError     extends ActiveDeliveryState {
  final String message;
  ActiveDeliveryError(this.message);
  @override List<Object?> get props => [message];
}
