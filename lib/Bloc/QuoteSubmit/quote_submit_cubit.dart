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
      return;
    }
    // CI4 fail() shape on a 400: { status:400, messages:{ error: "..." } }.
    // validateStatus is permissive so the body reaches us instead of throwing.
    final msg = _errorMessage(res);
    if (msg.toLowerCase().contains('insufficient')) {
      emit(QuoteSubmitInsufficientFunds(msg));
    } else {
      emit(QuoteSubmitError(msg));
    }
  }

  String _errorMessage(Map<String, dynamic> res) {
    final messages = res['messages'];
    if (messages is Map && messages['error'] != null) {
      return messages['error'].toString();
    }
    if (res['message'] != null) return res['message'].toString();
    return 'Failed to submit quote.';
  }
}
