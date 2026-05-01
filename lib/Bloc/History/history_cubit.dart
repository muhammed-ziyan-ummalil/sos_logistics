import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/delivery_model.dart';
import '../../utility/api_service.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(HistoryInitial());

  Future<void> fetch({int page = 1}) async {
    emit(HistoryLoading());
    final res = await ApiService.instance.post('driver/history', data: {'page': page});
    if (res['status'] == 'success') {
      final list = (res['data']?['deliveries'] ?? []) as List;
      emit(HistoryLoaded(
        list.map((e) => DeliveryHistoryItem.fromJson(e as Map<String, dynamic>)).toList(),
        page,
      ));
    } else {
      emit(HistoryError(res['message'] ?? 'Failed to load history.'));
    }
  }
}
