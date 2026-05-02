import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'owner_bank_details_state.dart';

class OwnerBankDetailsCubit extends Cubit<OwnerBankDetailsState> {
  OwnerBankDetailsCubit() : super(OwnerBankDetailsInitial());

  Future<void> fetchDetails() async {
    emit(OwnerBankDetailsLoading());
    final res = await ApiServiceV2.instance.get('owner/bank-details');
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      if (data.isEmpty ||
          (data['account_number'] == null && data['bank_name'] == null)) {
        emit(OwnerBankDetailsEmpty());
      } else {
        emit(OwnerBankDetailsLoaded(data));
      }
    } else {
      emit(OwnerBankDetailsError(
          res['message'] as String? ?? 'Failed to load bank details.'));
    }
  }

  Future<void> saveDetails({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    required String ifscCode,
  }) async {
    emit(OwnerBankDetailsSaving());
    final res = await ApiServiceV2.instance.post(
      'owner/bank-details',
      data: {
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
        'ifsc_code': ifscCode,
      },
    );
    if (res['status'] == 'success') {
      emit(OwnerBankDetailsSaved());
      await fetchDetails();
    } else {
      emit(OwnerBankDetailsSaveError(
          res['message'] as String? ?? 'Failed to save bank details.'));
    }
  }
}
