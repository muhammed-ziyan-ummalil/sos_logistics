import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/earnings_model.dart';
import '../../utility/api_service.dart';
import 'earnings_state.dart';

class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit() : super(EarningsInitial());

  Future<void> fetch() async {
    emit(EarningsLoading());
    final res = await ApiServiceV2.instance.get('driver/earnings');
    if (res['status'] == 'success') {
      emit(EarningsLoaded(EarningsData.fromJson(res['data'] as Map<String, dynamic>)));
    } else {
      emit(EarningsError(res['message'] ?? 'Failed to load earnings.'));
    }
  }
}
