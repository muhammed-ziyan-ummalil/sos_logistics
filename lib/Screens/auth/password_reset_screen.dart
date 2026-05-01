import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/password_reset_cubit.dart';
import '../../Bloc/Auth/password_reset_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../utility/shared_preference.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _newPassCtr  = TextEditingController();
  final _confPassCtr = TextEditingController();
  bool _obscureNew   = true;
  bool _obscureConf  = true;

  @override
  void dispose() {
    _newPassCtr.dispose();
    _confPassCtr.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PasswordResetCubit>().resetPassword(
      newPassword:     _newPassCtr.text.trim(),
      confirmPassword: _confPassCtr.text.trim(),
    );
  }

  Future<void> _navigateAfterReset() async {
    final roles        = await AppPrefs.getV2Roles();
    final selectedRole = await AppPrefs.getV2SelectedRole() ?? '';
    final session      = await AppPrefs.getV2Session();
    if (!mounted) return;

    if (selectedRole == UserRole.owner && roles.contains(UserRole.owner)) {
      final ownerStatus = session['ownerStatus'] ?? '';
      Navigator.pushReplacementNamed(
        context,
        ownerStatus == 'approved' ? AppRoutes.v2OwnerDashboard : AppRoutes.v2OwnerPending,
      );
    } else if (selectedRole == UserRole.driver && roles.contains(UserRole.driver)) {
      final driverStatus = session['driverStatus'] ?? '';
      Navigator.pushReplacementNamed(
        context,
        driverStatus == 'active' ? AppRoutes.home : AppRoutes.v2DriverDisabled,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PasswordResetCubit, PasswordResetState>(
      listener: (ctx, state) {
        if (state is PasswordResetSuccess) {
          _navigateAfterReset();
        } else if (state is PasswordResetError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 32.h),
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(Icons.lock_reset_rounded, color: AppColors.warning, size: 32.r),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Reset Your Password',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This is required before you can continue. Your account was set up with a temporary password.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                  ),
                  SizedBox(height: 32.h),
                  TextFormField(
                    controller: _newPassCtr,
                    obscureText: _obscureNew,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter new password';
                      if (v.trim().length < 6) return 'At least 6 characters required';
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _confPassCtr,
                    obscureText: _obscureConf,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscureConf = !_obscureConf),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Confirm your password';
                      if (v.trim() != _newPassCtr.text.trim()) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),
                  BlocBuilder<PasswordResetCubit, PasswordResetState>(
                    builder: (_, state) {
                      final loading = state is PasswordResetLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? SizedBox(
                                  height: 20.r,
                                  width:  20.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Password'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
