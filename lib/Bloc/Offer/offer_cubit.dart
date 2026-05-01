import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/delivery_model.dart';
import '../../utility/api_service.dart';
import 'offer_state.dart';

class OfferCubit extends Cubit<OfferState> {
  OfferCubit() : super(OfferInitial());

  Future<void> fetchActiveOffer() async {
    emit(OfferLoading());
    final res = await ApiService.instance.post('driver/active-offer');
    if (res['status'] == 'success') {
      final offerJson = res['data']?['offer'];
      if (offerJson == null) {
        emit(OfferNone());
      } else {
        emit(OfferAvailable(DeliveryOffer.fromJson(offerJson as Map<String, dynamic>)));
      }
    } else {
      emit(OfferError(res['message'] ?? 'Failed to fetch offer.'));
    }
  }

  Future<void> acceptOffer(int offerId) async {
    emit(OfferLoading());
    final res = await ApiService.instance.post('driver/offer/accept', data: {'offer_id': offerId});
    if (res['status'] == 'success') {
      final deliveryId = res['data']?['delivery_id'] as int? ?? 0;
      emit(OfferAccepted(deliveryId));
    } else {
      emit(OfferError(res['message'] ?? 'Failed to accept offer.'));
    }
  }

  Future<void> rejectOffer(int offerId) async {
    emit(OfferLoading());
    await ApiService.instance.post('driver/offer/reject', data: {'offer_id': offerId});
    emit(OfferRejected());
  }
}
