import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'owner_bank_details_state.dart';

class OwnerBankDetailsCubit extends Cubit<OwnerBankDetailsState> {
  OwnerBankDetailsCubit() : super(OwnerBankDetailsInitial());

  Future<void> fetchDetails() async {
    emit(OwnerBankDetailsLoading());
    final res = await ApiServiceUnified.instance.getOwnerBankDetails();
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final bank = data['bank'] is Map
          ? Map<String, dynamic>.from(data['bank'] as Map)
          : null;
      if (bank == null ||
          bank.isEmpty ||
          (bank['account_number'] == null && bank['bank_name'] == null)) {
        emit(OwnerBankDetailsEmpty());
      } else {
        emit(OwnerBankDetailsLoaded(bank));
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
    final res = await ApiServiceUnified.instance.saveOwnerBankDetails(
      bankName: bankName,
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
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
