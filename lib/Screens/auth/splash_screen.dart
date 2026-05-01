import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/driver_auth_cubit.dart';
import '../../Bloc/Auth/driver_auth_state.dart';
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
    context.read<DriverAuthCubit>().checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAuthCubit, DriverAuthState>(
      listener: (ctx, state) {
        if (state is DriverSplashChecked) {
          Navigator.pushReplacementNamed(
            ctx,
            state.isLoggedIn ? AppRoutes.home : AppRoutes.login,
          );
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
                'Driver Portal',
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
