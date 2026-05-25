import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay slightly for splash visibility, then init auth.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.read<AuthCubit>().init();
    });
  }

  void _routeFromAuth(BuildContext context, AuthAuthenticated state) {
    final caps = state.person.capabilities;

    final hasOwner  = caps.any((c) => c.capability == Capability.fleetOwner);
    final hasDriver = caps.any((c) => c.capability == Capability.driver);

    if (hasOwner && hasDriver) {
      // Both roles — let user pick.
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    if (hasOwner) {
      final ownerCap = caps.where((c) => c.capability == Capability.fleetOwner).firstOrNull;
      if (ownerCap == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        ownerCap.status == 'active'
            ? AppRoutes.v2OwnerDashboard
            : AppRoutes.v2OwnerPending,
      );
      return;
    }

    if (hasDriver) {
      final driverCap = caps.where((c) => c.capability == Capability.driver).firstOrNull;
      if (driverCap == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        driverCap.status == 'active'
            ? AppRoutes.home
            : AppRoutes.v2DriverDisabled,
      );
      return;
    }

    // Authenticated but no logistics capability — send to role selection / login.
    Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthMustResetPassword) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.v2PasswordReset);
        } else if (state is AuthAuthenticated) {
          _routeFromAuth(ctx, state);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 44.r),
              ),
              SizedBox(height: 20.h),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Delivery. Simplified.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
              ),
              SizedBox(height: 48.h),
              SizedBox(
                width: 28.r,
                height: 28.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
