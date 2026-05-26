import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import '../../Model/delivery_request_model.dart';
import 'delivery_feed_state.dart';

class DeliveryFeedCubit extends Cubit<DeliveryFeedState> {
  DeliveryFeedCubit() : super(DeliveryFeedInitial());

  Future<void> fetchFeed() async {
    emit(DeliveryFeedLoading());
    final res = await ApiServiceUnified.instance.get('owner/delivery-feed');
    if (res['status'] == 'success') {
      final list = (res['data'] as List? ?? [])
          .map((j) => DeliveryRequestModel.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(DeliveryFeedLoaded(list));
    } else {
      emit(DeliveryFeedError(res['message'] as String? ?? 'Failed to load delivery feed.'));
    }
  }
}
