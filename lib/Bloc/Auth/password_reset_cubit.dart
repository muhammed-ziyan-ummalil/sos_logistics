import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import 'password_reset_state.dart';

class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit() : super(PasswordResetInitial());

  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      emit(PasswordResetError('Passwords do not match.'));
      return;
    }
    if (newPassword.length < 6) {
      emit(PasswordResetError('Password must be at least 6 characters.'));
      return;
    }

    emit(PasswordResetLoading());

    final res = await ApiServiceV2.instance.post('auth/reset-password', data: {
      'new_password':     newPassword,
      'confirm_password': confirmPassword,
    });

    if (res['status'] == 'success') {
      // Clear must_reset flag in local storage
      final session = await AppPrefs.getV2Session();
      await AppPrefs.saveV2Session(
        token:        session['token'] ?? '',
        userId:       session['userId'] ?? '',
        name:         session['name'] ?? '',
        phone:        session['phone'] ?? '',
        roles:        await AppPrefs.getV2Roles(),
        mustReset:    false,
        ownerId:      session['ownerId'],
        ownerStatus:  session['ownerStatus'],
        driverId:     session['driverId'],
        driverStatus: session['driverStatus'],
        selectedRole: session['selectedRole'] ?? '',
      );
      emit(PasswordResetSuccess());
    } else {
      emit(PasswordResetError(res['message'] as String? ?? 'Reset failed.'));
    }
  }
}
