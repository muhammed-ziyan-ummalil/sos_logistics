import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/driver_auth_cubit.dart';
import '../../Bloc/Auth/driver_auth_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtr  = TextEditingController();
  final _passCtr   = TextEditingController();
  bool  _obscure   = true;

  @override
  void dispose() {
    _phoneCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DriverAuthCubit>().login(
      phone:    _phoneCtr.text.trim(),
      password: _passCtr.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAuthCubit, DriverAuthState>(
      listener: (ctx, state) {
        if (state is DriverAuthSuccess) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.home);
        } else if (state is DriverAuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32.r),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Welcome back',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Phone
                  TextFormField(
                    controller: _phoneCtr,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter phone number' : null,
                  ),
                  SizedBox(height: 16.h),

                  // Password
                  TextFormField(
                    controller: _passCtr,
                    obscureText: _obscure,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter password' : null,
                  ),
                  SizedBox(height: 32.h),

                  BlocBuilder<DriverAuthCubit, DriverAuthState>(
                    builder: (ctx, state) {
                      final loading = state is DriverAuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 24.h),
                  Center(
                    child: Text(
                      'Contact your fleet owner to get an account.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                      textAlign: TextAlign.center,
                    ),
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
