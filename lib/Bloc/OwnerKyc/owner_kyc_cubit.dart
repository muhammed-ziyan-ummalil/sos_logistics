import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utility/api_service.dart';
import 'owner_kyc_state.dart';

class OwnerKycCubit extends Cubit<OwnerKycState> {
  OwnerKycCubit() : super(OwnerKycInitial());

  Future<void> fetchDetails() async {
    emit(OwnerKycLoading());
    final res = await ApiServiceUnified.instance.getOwnerKycDetails();
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      emit(OwnerKycLoaded(
        status: (data['kyc_status'] ?? 'none') as String,
        kycMessage: data['kyc_message'] as String?,
        document: data['document'] as Map<String, dynamic>?,
      ));
    } else {
      emit(OwnerKycError(res['message']?.toString() ?? 'Failed to load KYC details.'));
    }
  }

  Future<void> submit({
    required String fullName,
    required String dob,
    required String panNumber,
    required String aadharNumber,
    String? panDocumentPath,
    String? aadharFrontPath,
    String? aadharBackPath,
  }) async {
    emit(OwnerKycSubmitting());
    final res = await ApiServiceUnified.instance.submitOwnerKyc(
      fullName: fullName,
      dob: dob,
      panNumber: panNumber,
      aadharNumber: aadharNumber,
      panDocumentPath: panDocumentPath,
      aadharFrontPath: aadharFrontPath,
      aadharBackPath: aadharBackPath,
    );
    if (res['status'] == 'success') {
      emit(OwnerKycSubmitSuccess(res['message']?.toString() ?? 'KYC submitted for review.'));
      await fetchDetails();
    } else {
      emit(OwnerKycError(res['message']?.toString() ?? 'Failed to submit KYC.'));
      await fetchDetails();
    }
  }
}
