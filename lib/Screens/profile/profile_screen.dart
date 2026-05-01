import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Auth/driver_auth_cubit.dart';
import '../../Bloc/Auth/driver_auth_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final res = await ApiService.instance.post('driver/profile');
    if (mounted && res['status'] == 'success') {
      setState(() {
        _profile = res['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAuthCubit, DriverAuthState>(
      listener: (ctx, state) {
        if (state is DriverLoggedOut) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: EdgeInsets.all(20.r),
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Icon(Icons.person_rounded, color: AppColors.primary, size: 40.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: Text(
                      _profile?['driver']?['name'] ?? '—',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: Text(
                      _profile?['driver']?['phone'] ?? '',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // KYC badge
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: _kycColor(_profile?['driver']?['kyc_status'] ?? 'pending').withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: _kycColor(_profile?['driver']?['kyc_status'] ?? 'pending').withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        'KYC: ${(_profile?['driver']?['kyc_status'] ?? 'pending').toUpperCase()}',
                        style: TextStyle(
                          color: _kycColor(_profile?['driver']?['kyc_status'] ?? 'pending'),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Vehicle info
                  if (_profile?['vehicle'] != null) ...[
                    _SectionTitle('Assigned Vehicle'),
                    SizedBox(height: 10.h),
                    _InfoTile(icon: Icons.directions_car_rounded, label: 'Registration', value: _profile!['vehicle']['reg_number'] ?? '—'),
                    _InfoTile(icon: Icons.category_rounded, label: 'Type', value: _profile!['vehicle']['type'] ?? '—'),
                    _InfoTile(icon: Icons.scale_rounded, label: 'Capacity', value: '${_profile!['vehicle']['capacity_kg'] ?? '—'} kg'),
                    SizedBox(height: 20.h),
                  ],

                  _SectionTitle('Availability'),
                  SizedBox(height: 10.h),
                  _InfoTile(
                    icon: Icons.wifi_tethering_rounded,
                    label: 'Status',
                    value: (_profile?['availability']?['status'] ?? 'offline').toUpperCase(),
                  ),
                  SizedBox(height: 32.h),

                  // Logout
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.6)),
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    onPressed: () => context.read<DriverAuthCubit>().logout(),
                  ),
                ],
              ),
      ),
    );
  }

  Color _kycColor(String status) {
    switch (status) {
      case 'verified': return AppColors.success;
      case 'rejected': return AppColors.error;
      default:         return AppColors.warning;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18.r),
          SizedBox(width: 12.w),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
          const Spacer(),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
