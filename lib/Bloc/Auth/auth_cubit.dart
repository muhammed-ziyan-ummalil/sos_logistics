import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import '../../core/app_constants.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> checkSession() async {
    final token = await AppPrefs.getV2Token();
    if (token == null || token.isEmpty) {
      emit(AuthNoSession());
      return;
    }
    final mustReset    = await AppPrefs.getV2MustReset();
    final roles        = await AppPrefs.getV2Roles();
    final selectedRole = await AppPrefs.getV2SelectedRole() ?? '';
    final session      = await AppPrefs.getV2Session();

    emit(AuthSessionRestored(
      token:        token,
      roles:        roles,
      mustReset:    mustReset,
      selectedRole: selectedRole,
      ownerStatus:  session['ownerStatus'],
      driverStatus: session['driverStatus'],
    ));
  }

  Future<void> login({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    emit(AuthLoading());

    final res = await ApiServiceV2.instance.post(
      'auth/login',
      data: {'email': email, 'password': password},
      withAuth: false,
    );

    if (res['status'] == 'success') {
      final data      = res['data'] as Map<String, dynamic>? ?? {};
      final token     = data['access_token'] as String? ?? '';
      final roles     = List<String>.from(data['roles'] as List? ?? []);
      final mustReset = (data['must_reset_password'] as bool?) ?? false;
      final user      = data['user']   as Map<String, dynamic>? ?? {};
      final owner     = data['owner']  as Map<String, dynamic>?;
      final driver    = data['driver'] as Map<String, dynamic>?;

      await AppPrefs.saveV2Session(
        token:        token,
        userId:       user['id']?.toString() ?? '',
        name:         user['name'] as String? ?? '',
        phone:        user['phone'] as String? ?? '',
        roles:        roles,
        mustReset:    mustReset,
        ownerId:      owner?['id']?.toString(),
        ownerStatus:  owner?['status'] as String?,
        driverId:     driver?['id']?.toString(),
        driverStatus: driver?['status'] as String?,
        selectedRole: selectedRole,
      );

      emit(AuthSuccess(
        token:        token,
        roles:        roles,
        mustReset:    mustReset,
        selectedRole: selectedRole,
        ownerStatus:  owner?['status'] as String?,
        driverStatus: driver?['status'] as String?,
      ));
    } else {
      emit(AuthError(res['message'] as String? ?? 'Login failed.'));
    }
  }

  Future<void> logout() async {
    await AppPrefs.clearV2();
    emit(AuthLoggedOut());
  }
}
