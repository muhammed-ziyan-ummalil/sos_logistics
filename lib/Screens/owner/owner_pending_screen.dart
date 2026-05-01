import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/auth_cubit.dart';
import '../../Bloc/Auth/auth_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';

class OwnerPendingScreen extends StatelessWidget {
  const OwnerPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthLoggedOut) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88.r,
                  height: 88.r,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 44.r),
                ),
                SizedBox(height: 28.h),
                Text(
                  'Approval Pending',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your fleet owner application is under review.\nYou will be notified once approved.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.divider),
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
