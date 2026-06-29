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
    String? vehicleName,
    String? rcNumber,
    String? imageFrontPath,
    String? imageBackPath,
    String? rcDocPath,
    String? insuranceDocPath,
    String? insuranceExpiry,
    double? minimumFee,
    double? perKmFee,
    double? maxDeliveryDistanceKm,
    double? includedDistanceKm,
    double? logisticGstPercent,
  }) async {
    emit(OwnerVehiclesLoading());

    final fields = <String, dynamic>{
      'reg_number': regNumber,
      'type':       type,
      if (vehicleName != null && vehicleName.isNotEmpty) 'vehicle_name': vehicleName,
      if (rcNumber != null && rcNumber.isNotEmpty) 'rc_number': rcNumber,
      if (capacityKg != null) 'capacity_kg': capacityKg,
      if (insuranceExpiry != null && insuranceExpiry.isNotEmpty) 'insurance_expiry': insuranceExpiry,
      if (minimumFee != null) 'minimum_fee': minimumFee,
      if (perKmFee != null) 'per_km_fee': perKmFee,
      if (maxDeliveryDistanceKm != null) 'max_delivery_distance_km': maxDeliveryDistanceKm,
      if (includedDistanceKm != null) 'included_distance_km': includedDistanceKm,
      if (logisticGstPercent != null) 'logistic_gst_percent': logisticGstPercent,
    };

    final files = <String, String>{};
    if (imageFrontPath != null) files['image_front'] = imageFrontPath;
    if (imageBackPath != null) files['image_back'] = imageBackPath;
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

  Future<void> updateVehicle({
    required int vehicleId,
    String? type,
    double? capacityKg,
    String? insuranceExpiry,
    double? minimumFee,
    double? perKmFee,
    double? maxDeliveryDistanceKm,
    double? includedDistanceKm,
    double? logisticGstPercent,
    String? imageFrontPath,
    String? imageBackPath,
    String? rcDocPath,
    String? insuranceDocPath,
  }) async {
    emit(OwnerVehiclesLoading());

    final fields = <String, dynamic>{
      if (type != null) 'type': type,
      if (capacityKg != null) 'capacity_kg': capacityKg,
      if (insuranceExpiry != null && insuranceExpiry.isNotEmpty) 'insurance_expiry': insuranceExpiry,
      if (minimumFee != null) 'minimum_fee': minimumFee,
      if (perKmFee != null) 'per_km_fee': perKmFee,
      if (maxDeliveryDistanceKm != null) 'max_delivery_distance_km': maxDeliveryDistanceKm,
      if (includedDistanceKm != null) 'included_distance_km': includedDistanceKm,
      if (logisticGstPercent != null) 'logistic_gst_percent': logisticGstPercent,
    };

    final files = <String, String>{};
    if (imageFrontPath != null) files['image_front'] = imageFrontPath;
    if (imageBackPath != null) files['image_back'] = imageBackPath;
    if (rcDocPath != null) files['rc_doc'] = rcDocPath;
    if (insuranceDocPath != null) files['insurance_doc'] = insuranceDocPath;

    final res = await ApiServiceV2.instance.postMultipart(
      'owner/vehicles/$vehicleId/update',
      fields,
      filePaths: files.isEmpty ? null : files,
    );

    if (res['status'] == 'success') {
      await fetchVehicles();
    } else {
      emit(OwnerVehiclesError(res['message'] as String? ?? 'Failed to update vehicle.'));
    }
  }
}
