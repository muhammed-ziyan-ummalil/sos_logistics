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

  // OTP generation must NOT replace the loaded delivery (that blanks the
  // screen). Emit OtpReady only as a transient signal for the listener (which
  // flips the OTP-entry flag), then restore the loaded delivery so the builder
  // keeps rendering. The driver never sees the OTP - the seller/buyer reads it
  // out to them (proof of presence).
  Future<void> _afterOtpAction(
      Map<String, dynamic> res, bool isPickup, ActiveDeliveryState prev) async {
    if (res['status'] == 'success') {
      emit(ActiveDeliveryOtpReady(isPickup: isPickup));
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Failed to generate OTP.'));
      // Delivery was cancelled server-side -> re-sync so the stale screen clears.
      if (res['cancelled'] == true) {
        await fetchActiveDelivery();
        return;
      }
    }
    if (prev is ActiveDeliveryLoaded) emit(prev);
  }

  Future<void> generatePickupOtp({required int deliveryId}) async {
    final prev = state;
    final res = await ApiServiceUnified.instance.generatePickupOtp(deliveryId);
    await _afterOtpAction(res, true, prev);
  }

  Future<void> generateDropOtp({required int deliveryId}) async {
    final prev = state;
    final res = await ApiServiceUnified.instance.generateDropOtp(deliveryId);
    await _afterOtpAction(res, false, prev);
  }

  Future<void> resendPickupOtp({required int deliveryId}) async {
    final prev = state;
    final res = await ApiServiceUnified.instance.resendPickupOtp(deliveryId);
    await _afterOtpAction(res, true, prev);
  }

  Future<void> resendDropOtp({required int deliveryId}) async {
    final prev = state;
    final res = await ApiServiceUnified.instance.resendDropOtp(deliveryId);
    await _afterOtpAction(res, false, prev);
  }

  // Do NOT emit Loading here: on the home screen the loaded delivery detail is
  // rendered inline, so a Loading state would unmount it (and its OTP-error
  // listener + OTP-entry field) mid-verify. On a wrong OTP we instead emit the
  // transient OtpError (caught by the detail view's listener -> snackbar) and
  // then re-emit the previous Loaded so the builder settles back on the detail
  // view without ever unmounting it - the driver keeps their OTP field, sees the
  // error, and can retype. Mirrors _afterOtpAction.
  Future<void> confirmPickup({required int deliveryId, required String otp}) async {
    final prev = state;
    final res  = await ApiServiceUnified.instance.verifyPickupOtp(deliveryId, otp);
    if (res['status'] == 'success') {
      await fetchActiveDelivery();
    } else {
      emit(ActiveDeliveryOtpError(res['message'] as String? ?? 'Invalid OTP.'));
      if (prev is ActiveDeliveryLoaded) emit(prev);
    }
  }

  Future<void> confirmDelivery({required int deliveryId, required String otp}) async {
    final prev = state;
    final res  = await ApiServiceUnified.instance.verifyDropOtp(deliveryId, otp);
    if (res['status'] == 'success') {
      emit(ActiveDeliveryCompleted());
      // Re-sync so the home detail clears (server now has no active delivery).
      await fetchActiveDelivery();
    } else {
      final isDispute = res['code'] == 'DISPUTE';
      emit(ActiveDeliveryOtpError(
        res['message'] as String? ?? 'Invalid OTP.',
        isDispute: isDispute,
      ));
      // Delivery was cancelled server-side -> re-sync so the stale screen clears.
      // Otherwise restore the loaded detail so the OTP field + error snackbar show.
      if (res['cancelled'] == true) {
        await fetchActiveDelivery();
      } else if (prev is ActiveDeliveryLoaded) {
        emit(prev);
      }
    }
  }
}
