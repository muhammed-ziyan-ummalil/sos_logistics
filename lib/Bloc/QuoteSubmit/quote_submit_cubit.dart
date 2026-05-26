import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'quote_submit_state.dart';

class QuoteSubmitCubit extends Cubit<QuoteSubmitState> {
  QuoteSubmitCubit() : super(QuoteSubmitInitial());

  Future<void> submitQuote(int requestId, int vehicleId) async {
    emit(QuoteSubmitLoading());
    final res = await ApiServiceUnified.instance.post(
      'owner/delivery-quote',
      data: {
        'request_id': requestId,
        'vehicle_id': vehicleId,
      },
    );
    if (res['status'] == 'success') {
      emit(QuoteSubmitSuccess(res['message'] as String? ?? 'Quote submitted.'));
    } else {
      emit(QuoteSubmitError(res['message'] as String? ?? 'Failed to submit quote.'));
    }
  }
}
