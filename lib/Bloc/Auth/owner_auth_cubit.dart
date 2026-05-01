import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import '../../core/app_constants.dart';
import 'owner_auth_state.dart';

class OwnerAuthCubit extends Cubit<OwnerAuthState> {
  OwnerAuthCubit() : super(OwnerAuthInitial());

  Future<void> login({required String phone, required String password}) async {
    emit(OwnerAuthLoading());
    final res = await ApiService.instance.post(
      'owner/login',
      data: {'phone': phone, 'password': password},
      withToken: false,
    );
    if (res['status'] == 'success') {
      final data  = res['data'] ?? {};
      final token = data['access_token'] ?? '';
      final owner = data['owner'] ?? {};
      await AppPrefs.saveOwnerToken(token);
      await AppPrefs.saveOwnerInfo(
        name:  owner['name']  ?? '',
        phone: owner['phone'] ?? '',
        id:    owner['id'].toString(),
      );
      await AppPrefs.saveUserRole(UserRole.owner);
      emit(OwnerAuthSuccess(token));
    } else {
      emit(OwnerAuthError(res['message'] ?? 'Login failed.'));
    }
  }

  Future<void> logout() async {
    await AppPrefs.clearAll();
    emit(OwnerLoggedOut());
  }
}
