import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/auth_cubit.dart';
import '../../Bloc/Auth/auth_state.dart';
import '../../Bloc/Auth/driver_auth_cubit.dart';
import '../../Bloc/Auth/driver_auth_state.dart';
import '../../Bloc/Auth/owner_auth_cubit.dart';
import '../../Bloc/Auth/owner_auth_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtr  = TextEditingController();
  final _passCtr   = TextEditingController();
  bool  _obscure   = true;
  late  String _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _role = (ModalRoute.of(context)?.settings.arguments as String?) ?? UserRole.driver;
  }

  @override
  void dispose() {
    _emailCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      email:        _emailCtr.text.trim(),
      password:     _passCtr.text.trim(),
      selectedRole: _role,
    );
  }

  bool _isLoading(DriverAuthState ds, OwnerAuthState os) =>
      _role == UserRole.driver ? ds is DriverAuthLoading : os is OwnerAuthLoading;

  @override
  Widget build(BuildContext context) {
    final isOwner = _role == UserRole.owner;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthSuccess) {
              if (state.mustReset) {
                Navigator.pushReplacementNamed(ctx, AppRoutes.v2PasswordReset);
                return;
              }
              if (state.selectedRole == UserRole.owner) {
                if (state.roles.contains(UserRole.owner)) {
                  Navigator.pushReplacementNamed(
                    ctx,
                    (state.ownerStatus == 'approved')
                        ? AppRoutes.v2OwnerDashboard
                        : AppRoutes.v2OwnerPending,
                  );
                } else {
                  Navigator.pushReplacementNamed(ctx, AppRoutes.v2NotAnOwner);
                }
              } else {
                if (state.roles.contains(UserRole.driver)) {
                  Navigator.pushReplacementNamed(
                    ctx,
                    (state.driverStatus == 'active')
                        ? AppRoutes.home
                        : AppRoutes.v2DriverDisabled,
                  );
                } else {
                  Navigator.pushReplacementNamed(ctx, AppRoutes.v2NotADriver);
                }
              }
            } else if (state is AuthError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            }
          },
        ),
        BlocListener<DriverAuthCubit, DriverAuthState>(
          listener: (ctx, state) {
            // Legacy listener kept for backward compat — V2 path handled above
          },
        ),
        BlocListener<OwnerAuthCubit, OwnerAuthState>(
          listener: (ctx, state) {
            // Legacy listener kept for backward compat — V2 path handled above
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: AppColors.textSecondary),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      isOwner
                          ? Icons.admin_panel_settings_rounded
                          : Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 32.r,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Welcome back',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isOwner ? 'Fleet Owner Login' : 'Driver Login',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isOwner
                        ? 'Sign in to manage your fleet and deliveries.'
                        : 'Sign in to start accepting delivery jobs.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                  ),
                  SizedBox(height: 36.h),
                  TextFormField(
                    controller: _emailCtr,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Enter email address';
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
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
                    builder: (_, ds) => BlocBuilder<OwnerAuthCubit, OwnerAuthState>(
                      builder: (_, os) {
                        final loading = _isLoading(ds, os);
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? SizedBox(
                                    height: 20.r,
                                    width:  20.r,
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
                  ),
                  SizedBox(height: 24.h),
                  if (isOwner)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.v2OwnerRegister),
                            child: Text(
                              'Create account',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
