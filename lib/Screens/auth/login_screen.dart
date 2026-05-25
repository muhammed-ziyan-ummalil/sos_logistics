import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sos_auth/sos_auth.dart';
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
      _emailCtr.text.trim(),
      _passCtr.text.trim(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isOwner = _role == UserRole.owner;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthMustResetPassword) {
              Navigator.pushReplacementNamed(ctx, AppRoutes.v2PasswordReset);
              return;
            }
            if (state is AuthAuthenticated) {
              final caps = state.person.capabilities;

              // Capability-driven routing — ignore the UI _role selection for
              // determining the destination; use it only for the "not found" error.
              if (_role == UserRole.owner) {
                final ownerCap = caps
                    .where((c) => c.capability == Capability.fleetOwner)
                    .firstOrNull;
                if (ownerCap != null) {
                  Navigator.pushReplacementNamed(
                    ctx,
                    ownerCap.status == 'active'
                        ? AppRoutes.v2OwnerDashboard
                        : AppRoutes.v2OwnerPending,
                  );
                } else {
                  Navigator.pushReplacementNamed(ctx, AppRoutes.v2NotAnOwner);
                }
              } else {
                final driverCap = caps
                    .where((c) => c.capability == Capability.driver)
                    .firstOrNull;
                if (driverCap != null) {
                  Navigator.pushReplacementNamed(
                    ctx,
                    driverCap.status == 'active'
                        ? AppRoutes.home
                        : AppRoutes.v2DriverDisabled,
                  );
                } else {
                  Navigator.pushReplacementNamed(ctx, AppRoutes.v2NotADriver);
                }
              }
            } else if (state is AuthError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppTheme.error(context)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: AppTheme.textSecondary(context)),
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
                      color: AppTheme.primary(context),
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
                    style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isOwner ? 'Fleet Owner Login' : 'Driver Login',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isOwner
                        ? 'Sign in to manage your fleet and deliveries.'
                        : 'Sign in to start accepting delivery jobs.',
                    style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.sp),
                  ),
                  SizedBox(height: 36.h),
                  TextFormField(
                    controller: _emailCtr,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary(context)),
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
                    style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary(context)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textSecondary(context),
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter password' : null,
                  ),
                  SizedBox(height: 32.h),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (_, state) {
                      final loading = state is AuthLoading;

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
                  SizedBox(height: 24.h),
                  if (isOwner)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.sp),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.v2OwnerRegister),
                            child: Text(
                              'Create account',
                              style: TextStyle(
                                color: AppTheme.primary(context),
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
                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12.sp),
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
