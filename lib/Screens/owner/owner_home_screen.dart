import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/owner_auth_cubit.dart';
import '../../Bloc/Auth/owner_auth_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerAuthCubit, OwnerAuthState>(
      listener: (ctx, state) {
        if (state is OwnerLoggedOut) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Fleet Dashboard'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 22.r),
              onPressed: () => context.read<OwnerAuthCubit>().logout(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(Icons.admin_panel_settings_rounded, color: AppColors.textSecondary, size: 32.r),
              ),
              SizedBox(height: 16.h),
              Text(
                'Fleet Dashboard',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Text(
                'Coming soon',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
