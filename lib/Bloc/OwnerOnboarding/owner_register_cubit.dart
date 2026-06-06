import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'owner_register_state.dart';

class OwnerRegisterCubit extends Cubit<OwnerRegisterState> {
  OwnerRegisterCubit() : super(OwnerRegisterInitial());

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String sessionId,
    String? businessName,
    String? kycDocPath,
    required String vehicleRegNumber,
    required String vehicleType,
    double? capacityKg,
    String? gender,
    String? addressLine,
    String? area,
    String? city,
    String? state,
    String? pincode,
  }) async {
    emit(OwnerRegisterLoading());

    final fields = <String, dynamic>{
      'name':                name,
      'email':               email,
      'phone':               phone,
      'password':            password,
      'session_id':          sessionId,
      'vehicle_reg_number':  vehicleRegNumber,
      'vehicle_type':        vehicleType,
      if (businessName != null && businessName.isNotEmpty) 'business_name': businessName,
      if (capacityKg != null) 'vehicle_capacity_kg': capacityKg,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (addressLine != null && addressLine.isNotEmpty) 'address_line': addressLine,
      if (area != null && area.isNotEmpty) 'area': area,
      if (city != null && city.isNotEmpty) 'city': city,
      if (state != null && state.isNotEmpty) 'state': state,
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
    };

    final files = kycDocPath != null ? <String, String>{'kyc_doc': kycDocPath} : null;

    try {
      final res = await ApiServiceV2.instance.postMultipart(
        'owner/register',
        fields,
        filePaths: files,
        withAuth: false,
      );

      if (res['status'] == 'success') {
        emit(OwnerRegisterSuccess());
      } else {
        emit(OwnerRegisterError(res['message'] as String? ?? 'Registration failed.'));
      }
    } catch (e) {
      emit(OwnerRegisterError('Network error. Please try again.'));
    }
  }
}
