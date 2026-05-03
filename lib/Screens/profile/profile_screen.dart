import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Bloc/Auth/driver_auth_cubit.dart';
import '../../Bloc/Auth/driver_auth_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../core/theme_controller.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import '../owner/account/owner_about_screen.dart';
import '../owner/account/owner_privacy_screen.dart';
import '../owner/account/owner_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name  = '';
  String _phone = '';
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await AppPrefs.getV2Session();
    if (mounted) {
      setState(() {
        _name  = session['name']  ?? '';
        _phone = session['phone'] ?? '';
      });
    }
    final res = await ApiServiceV2.instance.get('driver/me');
    if (mounted) {
      setState(() {
        if (res['status'] == 'success') {
          _data = res['data'] as Map<String, dynamic>?;
        }
        _loading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic>? get _driver       => _data?['driver']       as Map<String, dynamic>?;
  Map<String, dynamic>? get _vehicle      => _data?['vehicle']      as Map<String, dynamic>?;
  Map<String, dynamic>? get _availability => _data?['availability'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _owner        => _data?['owner']        as Map<String, dynamic>?;

  String get _kycStatus => _driver?['kyc_status'] as String? ?? 'submitted';

  Color _kycColor(String s) {
    switch (s) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'submitted': return AppColors.warning;
      default:         return AppColors.warning;
    }
  }

  String _kycLabel(String s) {
    switch (s) {
      case 'approved':  return 'KYC VERIFIED';
      case 'rejected':  return 'KYC REJECTED';
      case 'submitted': return 'KYC SUBMITTED';
      default:          return 'KYC PENDING';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<DriverAuthCubit, DriverAuthState>(
      listener: (ctx, state) {
        if (state is DriverLoggedOut) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.background : AppLightColors.background,
        body: Column(
          children: [
            _buildHeader(isDark),
            _buildProfileCard(isDark),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2.5))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 8.h),
                          _buildFleetSection(isDark),
                          SizedBox(height: 8.h),
                          _buildServicesSection(isDark),
                          SizedBox(height: 8.h),
                          _buildAppSection(isDark),
                          SizedBox(height: 8.h),
                          _buildSignOutSection(isDark),
                          SizedBox(height: 24.h),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppLightColors.textSecondary),
                          ),
                          SizedBox(height: 80.h),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final surface  = isDark ? AppColors.surface : AppLightColors.surface;
    final divider  = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;

    return Container(
      color: surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: surface,
            border: Border(bottom: BorderSide(color: divider, width: 1)),
          ),
          child: Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(bool isDark) {
    final surface      = isDark ? AppColors.surface : AppLightColors.surface;
    final primary      = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final textPrimary  = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final kycColor     = _kycColor(_kycStatus);

    final displayName = _driver?['name'] as String? ?? _name;

    return Container(
      color: surface,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Row(
        children: [
          // Avatar with initial
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withOpacity(0.12),
              border: Border.all(color: primary.withOpacity(0.25), width: 1.5),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : 'Driver',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _driver?['phone'] as String? ?? _phone,
                  style: TextStyle(fontSize: 13.sp, color: textSecondary),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        'DRIVER',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: kycColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: kycColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        _kycLabel(_kycStatus),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: kycColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Fleet section ─────────────────────────────────────────────────────────
  Widget _buildFleetSection(bool isDark) {
    final ownerName = _owner?['name'] as String? ?? '—';
    final bizName   = _owner?['business_name'] as String?;
    final ownerLabel = bizName != null && bizName.isNotEmpty
        ? '$ownerName · $bizName'
        : ownerName;

    final vehicleReg  = _vehicle?['reg_number'] as String? ?? '—';
    final vehicleType = (_vehicle?['type'] as String? ?? '').toUpperCase();
    final vehicleLabel = _vehicle != null ? '$vehicleReg · $vehicleType' : 'Not assigned';

    final availStatus = (_availability?['status'] as String? ?? 'offline').toUpperCase();

    return _menuGroup(
      isDark: isDark,
      title: 'Fleet',
      tiles: [
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.business_rounded,
          title: 'Works Under',
          trailing: _infoValue(isDark, ownerLabel),
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.directions_car_rounded,
          title: 'Assigned Vehicle',
          trailing: _infoValue(isDark, vehicleLabel),
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.sensors_rounded,
          title: 'Availability',
          trailing: _statusBadge(availStatus),
        ),
      ],
    );
  }

  Widget _infoValue(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isOnline = status == 'ONLINE';
    final color = isOnline ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Services section ──────────────────────────────────────────────────────
  Widget _buildServicesSection(bool isDark) {
    return _menuGroup(
      isDark: isDark,
      title: 'Services',
      tiles: [
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.bar_chart_rounded,
          title: 'My Earnings',
          onTap: () {},
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.history_rounded,
          title: 'Delivery History',
          onTap: () {},
        ),
      ],
    );
  }

  // ── App section ───────────────────────────────────────────────────────────
  Widget _buildAppSection(bool isDark) {
    return _menuGroup(
      isDark: isDark,
      title: 'App',
      tiles: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (_, mode, __) => _DriverMenuTile(
            isDark: isDark,
            icon: Icons.brightness_medium_outlined,
            title: 'Appearance',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ThemeController.label(mode),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.r,
                  color: isDark ? AppColors.divider : AppLightColors.divider,
                ),
              ],
            ),
            onTap: () => _showAppearanceSheet(isDark, mode),
          ),
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerPrivacyScreen())),
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerPrivacyScreen())),
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.info_outline_rounded,
          title: 'About Us',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerAboutScreen())),
        ),
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.support_agent_outlined,
          title: 'Support',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerSupportScreen())),
        ),
      ],
    );
  }

  // ── Sign out section ──────────────────────────────────────────────────────
  Widget _buildSignOutSection(bool isDark) {
    return _menuGroup(
      isDark: isDark,
      title: '',
      tiles: [
        _DriverMenuTile(
          isDark: isDark,
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  // ── Appearance sheet ──────────────────────────────────────────────────────
  void _showAppearanceSheet(bool isDark, ThemeMode current) {
    final surface   = isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primary   = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final divider   = isDark ? AppColors.divider : AppLightColors.divider;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Appearance',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2)),
            Text('Choose how the app looks on your device.',
                style: TextStyle(fontSize: 13.sp, color: textSecondary)),
            SizedBox(height: 20.h),
            ...[ThemeMode.light, ThemeMode.dark, ThemeMode.system].map((mode) {
              final selected = current == mode;
              return GestureDetector(
                onTap: () {
                  themeController.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selected
                          ? primary.withOpacity(0.30)
                          : divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == ThemeMode.light
                            ? Icons.light_mode_outlined
                            : mode == ThemeMode.dark
                                ? Icons.dark_mode_outlined
                                : Icons.brightness_auto_outlined,
                        size: 18.r,
                        color: selected ? primary : textSecondary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          ThemeController.label(mode),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? primary : textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            size: 18.r, color: primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────
  Future<void> _showLogoutDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surface : AppLightColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Sign Out',
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimary
                  : AppLightColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14.sp,
              color: isDark
                  ? AppColors.textSecondary
                  : AppLightColors.textSecondary,
              height: 1.5),
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(_, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<DriverAuthCubit>().logout();
    }
  }

  // ── Menu group builder ────────────────────────────────────────────────────
  Widget _menuGroup({
    required bool isDark,
    required String title,
    required List<Widget> tiles,
  }) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final cardColor = isDark ? AppColors.surface : AppLightColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Container(color: cardColor, child: Column(children: tiles)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DriverMenuTile  — identical layout to _OwnerMenuTile
// ─────────────────────────────────────────────────────────────────────────────
class _DriverMenuTile extends StatelessWidget {
  final bool      isDark;
  final IconData  icon;
  final String    title;
  final VoidCallback? onTap;
  final Widget?   trailing;

  const _DriverMenuTile({
    required this.isDark,
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor   = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final textColor   = isDark ? AppColors.textPrimary   : AppLightColors.textPrimary;
    final divider     = isDark ? AppColors.divider       : AppLightColors.divider;
    final card        = isDark ? AppColors.surface       : AppLightColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: card,
          border: Border(bottom: BorderSide(color: divider, width: 0.8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: iconColor),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor),
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded, size: 18.r, color: divider)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
