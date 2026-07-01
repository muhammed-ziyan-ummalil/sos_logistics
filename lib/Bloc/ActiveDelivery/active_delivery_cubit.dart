import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/delivery_model.dart';
import '../../utility/api_service.dart';
import 'active_delivery_state.dart';

class ActiveDeliveryCubit extends Cubit<ActiveDeliveryState> {
  ActiveDeliveryCubit() : super(ActiveDeliveryInitial());

  Future<void> fetchActiveDelivery() async {
    // V2 client — Bearer token auth
    final res = await ApiServiceV2.instance.post('driver/active-delivery');
    if (res['status'] == 'success') {
      final d = res['data']?['delivery'];
      if (d == null) {
        emit(ActiveDeliveryNone());
      } else {
        emit(ActiveDeliveryLoaded(ActiveDelivery.fromJson(d as Map<String, dynamic>)));
      }
    } else {
      emit(ActiveDeliveryError(res['message'] as String? ?? 'Failed.'));
    }
  }

  Future<void> generatePickupOtp({required int deliveryId}) async {
    emit(ActiveDeliveryLoading());
    final res = await ApiServiceUnified.instance.generatePickupOtp(deliveryId);
    if (res['status'] == 'success') {
      emit(ActiveDeliveryOtpReady(isPickup: true, testOtp: res['otp']?.toString()));
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Failed to generate OTP.'));
    }
  }

  Future<void> generateDropOtp({required int deliveryId}) async {
    emit(ActiveDeliveryLoading());
    final res = await ApiServiceUnified.instance.generateDropOtp(deliveryId);
    if (res['status'] == 'success') {
      emit(ActiveDeliveryOtpReady(isPickup: false, testOtp: res['otp']?.toString()));
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Failed to generate OTP.'));
    }
  }

  Future<void> resendPickupOtp({required int deliveryId}) async {
    final res = await ApiServiceUnified.instance.resendPickupOtp(deliveryId);
    if (res['status'] == 'success') {
      emit(ActiveDeliveryOtpReady(isPickup: true, testOtp: res['otp']?.toString()));
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Failed to resend OTP.'));
    }
  }

  Future<void> resendDropOtp({required int deliveryId}) async {
    final res = await ApiServiceUnified.instance.resendDropOtp(deliveryId);
    if (res['status'] == 'success') {
      emit(ActiveDeliveryOtpReady(isPickup: false, testOtp: res['otp']?.toString()));
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Failed to resend OTP.'));
    }
  }

  Future<void> confirmPickup({required int deliveryId, required String otp}) async {
    emit(ActiveDeliveryLoading());
    final res = await ApiServiceUnified.instance.verifyPickupOtp(deliveryId, otp);
    if (res['status'] == 'success') {
      await fetchActiveDelivery();
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Invalid OTP.'));
    }
  }

  Future<void> confirmDelivery({required int deliveryId, required String otp}) async {
    emit(ActiveDeliveryLoading());
    final res = await ApiServiceUnified.instance.verifyDropOtp(deliveryId, otp);
    if (res['status'] == 'success') {
      emit(ActiveDeliveryCompleted());
      // Re-sync so the home banner clears (server now has no active delivery).
      await fetchActiveDelivery();
    } else {
      final isDispute = res['code'] == 'DISPUTE';
      emit(ActiveDeliveryOtpError(
        res['message'] as String? ?? 'Invalid OTP.',
        isDispute: isDispute,
      ));
    }
  }
}
