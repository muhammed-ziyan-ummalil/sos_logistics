import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../utility/shared_preference.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // V2 session check first
    final v2Token = await AppPrefs.getV2Token();
    if (v2Token != null && v2Token.isNotEmpty) {
      final mustReset    = await AppPrefs.getV2MustReset();
      if (mustReset) {
        Navigator.pushReplacementNamed(context, AppRoutes.v2PasswordReset);
        return;
      }
      final roles        = await AppPrefs.getV2Roles();
      final selectedRole = await AppPrefs.getV2SelectedRole() ?? '';
      final session      = await AppPrefs.getV2Session();

      if (selectedRole == UserRole.owner && roles.contains(UserRole.owner)) {
        final ownerStatus = session['ownerStatus'] ?? '';
        Navigator.pushReplacementNamed(
          context,
          ownerStatus == 'approved' ? AppRoutes.v2OwnerDashboard : AppRoutes.v2OwnerPending,
        );
        return;
      }
      if (selectedRole == UserRole.driver && roles.contains(UserRole.driver)) {
        final driverStatus = session['driverStatus'] ?? '';
        Navigator.pushReplacementNamed(
          context,
          driverStatus == 'active' ? AppRoutes.home : AppRoutes.v2DriverDisabled,
        );
        return;
      }
      // Has V2 token but role mismatch — go to role selection
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    // Legacy fallback
    final role = await AppPrefs.getUserRole();
    if (role == UserRole.driver) {
      final token = await AppPrefs.getToken();
      Navigator.pushReplacementNamed(
        context,
        (token != null && token.isNotEmpty) ? AppRoutes.home : AppRoutes.roleSelection,
      );
    } else if (role == UserRole.owner) {
      final token = await AppPrefs.getOwnerToken();
      Navigator.pushReplacementNamed(
        context,
        (token != null && token.isNotEmpty) ? AppRoutes.ownerHome : AppRoutes.roleSelection,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
