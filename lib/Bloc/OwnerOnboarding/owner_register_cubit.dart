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
    String? gender,
    String? addressLine,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? serviceLat,
    String? serviceLng,
    String? serviceRadiusKm,
  }) async {
    emit(OwnerRegisterLoading());

    // Identity-only registration. Vehicle + KYC are added later from the owner
    // app, matching the farmer/agent registration shape.
    final fields = <String, dynamic>{
      'name':                name,
      'email':               email,
      'phone':               phone,
      'password':            password,
      'session_id':          sessionId,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (addressLine != null && addressLine.isNotEmpty) 'address_line': addressLine,
      if (area != null && area.isNotEmpty) 'area': area,
      if (city != null && city.isNotEmpty) 'city': city,
      if (state != null && state.isNotEmpty) 'state': state,
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      // Service-area centre + radius for delivery region targeting
      // (vehicle_owners.service_lat / service_lng / service_radius_km).
      if (serviceLat != null && serviceLat.isNotEmpty) 'service_lat': serviceLat,
      if (serviceLng != null && serviceLng.isNotEmpty) 'service_lng': serviceLng,
      if (serviceRadiusKm != null && serviceRadiusKm.isNotEmpty)
        'service_radius_km': serviceRadiusKm,
    };

    const Map<String, String>? files = null;

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
