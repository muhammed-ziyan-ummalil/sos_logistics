import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import 'owner_profile_state.dart';

class OwnerProfileCubit extends Cubit<OwnerProfileState> {
  OwnerProfileCubit() : super(OwnerProfileInitial());

  Future<void> fetchProfile() async {
    emit(OwnerProfileLoading());
    final res = await ApiServiceV2.instance.get('owner/me');
    if (res['status'] == 'success') {
      emit(OwnerProfileLoaded(Map<String, dynamic>.from(res['data'] as Map? ?? {})));
    } else {
      emit(OwnerProfileError(res['message'] as String? ?? 'Failed to load profile.'));
    }
  }

  Future<void> updateProfile({
    required String name,
    String? gender,
    String? addressLine,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? photoPath,
  }) async {
    final current = state is OwnerProfileLoaded
        ? (state as OwnerProfileLoaded).data
        : <String, dynamic>{};
    emit(OwnerProfileUpdating(Map<String, dynamic>.from(current)));

    final fields = <String, dynamic>{
      'name': name,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (addressLine != null) 'address_line': addressLine,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
    };

    Map<String, dynamic> res;
    if (photoPath != null) {
      res = await ApiServiceV2.instance.postMultipart(
        'owner/me/update',
        fields,
        filePaths: {'profile_photo': photoPath},
      );
    } else {
      res = await ApiServiceV2.instance.post('owner/me/update', data: fields);
    }

    if (res['status'] == 'success') {
      await _patchLocalName(name);
      emit(OwnerProfileUpdated(Map<String, dynamic>.from(res['data'] as Map? ?? {})));
    } else {
      emit(OwnerProfileError(res['message'] as String? ?? 'Update failed.'));
    }
  }

  Future<void> _patchLocalName(String name) async {
    final s = await AppPrefs.getV2Session();
    final roles = (s['roles'] ?? '').split(',').where((r) => r.isNotEmpty).toList();
    await AppPrefs.saveV2Session(
      token:        s['token']        ?? '',
      userId:       s['userId']       ?? '',
      name:         name,
      phone:        s['phone']        ?? '',
      roles:        roles,
      mustReset:    false,
      ownerId:      s['ownerId'],
      ownerStatus:  s['ownerStatus'],
      driverId:     s['driverId'],
      driverStatus: s['driverStatus'],
      selectedRole: s['selectedRole'] ?? '',
    );
  }
}
