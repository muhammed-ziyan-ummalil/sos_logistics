import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'owner_vehicles_state.dart';

class OwnerVehiclesCubit extends Cubit<OwnerVehiclesState> {
  OwnerVehiclesCubit() : super(OwnerVehiclesInitial());

  Future<void> fetchVehicles() async {
    emit(OwnerVehiclesLoading());
    final res = await ApiServiceV2.instance.get('owner/vehicles');
    if (res['status'] == 'success') {
      final list = (res['data']?['vehicles'] as List?) ?? [];
      final vehicles = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      emit(OwnerVehiclesLoaded(vehicles));
    } else {
      emit(OwnerVehiclesError(res['message'] as String? ?? 'Failed to load vehicles.'));
    }
  }

  Future<void> addVehicle({
    required String regNumber,
    required String type,
    double? capacityKg,
    String? rcDocPath,
    String? insuranceDocPath,
    String? insuranceExpiry,
  }) async {
    emit(OwnerVehiclesLoading());

    final fields = <String, dynamic>{
      'reg_number': regNumber,
      'type':       type,
      if (capacityKg != null) 'capacity_kg': capacityKg,
      if (insuranceExpiry != null && insuranceExpiry.isNotEmpty) 'insurance_expiry': insuranceExpiry,
    };

    final files = <String, String>{};
    if (rcDocPath != null) files['rc_doc'] = rcDocPath;
    if (insuranceDocPath != null) files['insurance_doc'] = insuranceDocPath;

    final res = await ApiServiceV2.instance.postMultipart(
      'owner/vehicles',
      fields,
      filePaths: files.isEmpty ? null : files,
    );

    if (res['status'] == 'success') {
      await fetchVehicles();
    } else {
      emit(OwnerVehiclesError(res['message'] as String? ?? 'Failed to add vehicle.'));
    }
  }
}
