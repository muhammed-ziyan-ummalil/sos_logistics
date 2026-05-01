import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import 'driver_auth_state.dart';

class DriverAuthCubit extends Cubit<DriverAuthState> {
  DriverAuthCubit() : super(DriverAuthInitial());

  Future<void> checkSession() async {
    final token = await AppPrefs.getToken();
    emit(DriverSplashChecked(token != null && token.isNotEmpty));
  }

  Future<void> login({required String phone, required String password}) async {
    emit(DriverAuthLoading());
    final res = await ApiService.instance.post(
      'driver/login',
      data: {'phone': phone, 'password': password},
      withToken: false,
    );
    if (res['status'] == 'success') {
      final data = res['data'] ?? {};
      final token = data['access_token'] ?? '';
      final driver = data['driver'] ?? {};
      await AppPrefs.saveToken(token);
      await AppPrefs.saveDriverInfo(
        name:  driver['name'] ?? '',
        phone: driver['phone'] ?? '',
        id:    driver['id'].toString(),
      );
      emit(DriverAuthSuccess(token));
    } else {
      emit(DriverAuthError(res['message'] ?? 'Login failed.'));
    }
  }

  Future<void> logout() async {
    await AppPrefs.clearAll();
    emit(DriverLoggedOut());
  }
}
