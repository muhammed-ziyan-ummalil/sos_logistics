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
    };

    final files = kycDocPath != null ? <String, String>{'kyc_doc': kycDocPath} : null;

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
  }
}
