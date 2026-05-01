import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/delivery_model.dart';
import '../../utility/api_service.dart';
import 'active_delivery_state.dart';

class ActiveDeliveryCubit extends Cubit<ActiveDeliveryState> {
  ActiveDeliveryCubit() : super(ActiveDeliveryInitial());

  Future<void> fetchActiveDelivery() async {
    emit(ActiveDeliveryLoading());
    final res = await ApiService.instance.post('driver/active-delivery');
    if (res['status'] == 'success') {
      final d = res['data']?['delivery'];
      if (d == null) {
        emit(ActiveDeliveryNone());
      } else {
        emit(ActiveDeliveryLoaded(ActiveDelivery.fromJson(d as Map<String, dynamic>)));
      }
    } else {
      emit(ActiveDeliveryError(res['message'] ?? 'Failed.'));
    }
  }

  Future<void> confirmPickup({required int deliveryId, required String otp}) async {
    emit(ActiveDeliveryLoading());
    final res = await ApiService.instance.post(
      'driver/pickup-otp',
      data: {'delivery_id': deliveryId, 'otp': otp},
    );
    if (res['status'] == 'success') {
      await fetchActiveDelivery();
    } else {
      emit(ActiveDeliveryOtpError(res['message'] ?? 'Invalid OTP.'));
    }
  }

  Future<void> confirmDelivery({required int deliveryId, required String otp}) async {
    emit(ActiveDeliveryLoading());
    final res = await ApiService.instance.post(
      'driver/deliver',
      data: {'delivery_id': deliveryId, 'otp': otp},
    );
    if (res['status'] == 'success') {
      emit(ActiveDeliveryCompleted());
    } else {
      final isDispute = res['code'] == 'DISPUTE';
      emit(ActiveDeliveryOtpError(res['message'] ?? 'Invalid OTP.', isDispute: isDispute));
    }
  }
}
