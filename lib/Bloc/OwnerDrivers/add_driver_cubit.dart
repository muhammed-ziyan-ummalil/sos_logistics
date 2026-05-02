import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'add_driver_state.dart';

class AddDriverCubit extends Cubit<AddDriverState> {
  AddDriverCubit() : super(AddDriverInitial());

  Future<void> createDriver({
    required String name,
    required String email,
    required String phone,
    String? licenseNumber,
    String? licenseDocPath,
    String? idProofDocPath,
    String? licenseExpiry,
  }) async {
    emit(AddDriverLoading());

    final fields = <String, dynamic>{
      'name':  name,
      'email': email,
      'phone': phone,
      if (licenseNumber != null && licenseNumber.isNotEmpty) 'license_number': licenseNumber,
      if (licenseExpiry != null && licenseExpiry.isNotEmpty) 'license_expiry': licenseExpiry,
    };

    final files = <String, String>{};
    if (licenseDocPath != null) files['license_doc']  = licenseDocPath;
    if (idProofDocPath != null) files['id_proof_doc'] = idProofDocPath;

    final res = await ApiServiceV2.instance.postMultipart(
      'owner/drivers',
      fields,
      filePaths: files.isEmpty ? null : files,
    );

    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      emit(AddDriverSuccess(
        driverId:     data['driver_id']?.toString() ?? '',
        tempPassword: data['temp_password'] as String? ?? '',
      ));
    } else {
      emit(AddDriverError(res['message'] as String? ?? 'Failed to create driver.'));
    }
  }

  void reset() => emit(AddDriverInitial());
}
