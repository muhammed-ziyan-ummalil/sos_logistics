import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sos_auth/sos_auth.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../core/theme_controller.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import '../../widgets/widgets.dart';
import '../history/history_screen.dart';
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
  Map<String, dynamic>? get _owner        => _data?['owner']        as Map<String, dynamic>?;

  String get _accountStatus => (_driver?['status'] as String? ?? 'active').toLowerCase();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: Column(
          children: [
            _buildHeader(context),
            _buildProfileCard(context),
            Expanded(
              child: _loading
                  ? _buildLoadingSkeleton()
                  : SingleChildScrollView(
                      child: Builder(builder: (context) {
                        final authState = context.watch<AuthCubit>().state;
                        final hasBuyer = authState is AuthAuthenticated &&
                            authState.person.hasCap(Capability.buyer);
                        return Column(
                        children: [
                          if (hasBuyer) ...[
                            SizedBox(height: 8.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: const _MarketplaceBadge(),
                            ),
                          ],
                          SizedBox(height: 8.h),
                          _buildFleetSection(context),
                          SizedBox(height: 8.h),
                          _buildServicesSection(context),
                          SizedBox(height: 8.h),
                          _buildAppSection(context),
                          SizedBox(height: 8.h),
                          _buildSignOutSection(context),
                          SizedBox(height: 24.h),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondary(context)),
                          ),
                          SizedBox(height: 80.h),
                        ],
                      );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 56.h),
          SizedBox(height: 12.h),
          SkeletonBox(width: double.infinity, height: 56.h),
          SizedBox(height: 12.h),
          SkeletonBox(width: double.infinity, height: 56.h),
          SizedBox(height: 12.h),
          SkeletonBox(width: double.infinity, height: 56.h),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.surface(context),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            border: Border(bottom: BorderSide(color: AppTheme.divider(context), width: 1)),
          ),
          child: Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
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
  Widget _buildProfileCard(BuildContext context) {
    final primary = AppTheme.primary(context);
    final displayName = _driver?['name'] as String? ?? _name;
    final accountStatus = _accountStatus;

    return Container(
      color: AppTheme.surface(context),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Row(
        children: [
          // Avatar with initial
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
              border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.5),
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
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _driver?['phone'] as String? ?? _phone,
                  style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary(context)),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    SosChip(label: 'DRIVER', tone: SosTone.info),
                    SizedBox(width: 6.w),
                    SosChip(
                      label: accountStatus == 'active' ? 'ACTIVE' : 'SUSPENDED',
                      tone: accountStatus == 'active' ? SosTone.success : SosTone.error,
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
  Widget _buildFleetSection(BuildContext context) {
    final ownerName = _owner?['name'] as String? ?? '—';
    final bizName   = _owner?['business_name'] as String?;
    final ownerLabel = bizName != null && bizName.isNotEmpty
        ? '$ownerName · $bizName'
        : ownerName;

    final vehicleReg  = _vehicle?['reg_number'] as String? ?? '—';
    final vehicleType = (_vehicle?['type'] as String? ?? '').toUpperCase();
    final vehicleLabel = _vehicle != null ? '$vehicleReg · $vehicleType' : 'Not assigned';

    return _menuGroup(
      context: context,
      title: 'Fleet',
      tiles: [
        _DriverMenuTile(
          icon: Icons.business_rounded,
          title: 'Works Under',
          trailing: Text(
            ownerLabel,
            style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary(context)),
          ),
        ),
        _DriverMenuTile(
          icon: Icons.directions_car_rounded,
          title: 'Assigned Vehicle',
          trailing: Text(
            vehicleLabel,
            style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary(context)),
          ),
        ),
      ],
    );
  }

  // ── Services section ──────────────────────────────────────────────────────
  Widget _buildServicesSection(BuildContext context) {
    return _menuGroup(
      context: context,
      title: 'Services',
      tiles: [
        _DriverMenuTile(
          icon: Icons.history_rounded,
          title: 'Delivery History',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
      ],
    );
  }

  // ── App section ───────────────────────────────────────────────────────────
  Widget _buildAppSection(BuildContext context) {
    return _menuGroup(
      context: context,
      title: 'App',
      tiles: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (_, mode, __) => _DriverMenuTile(
            icon: Icons.brightness_medium_outlined,
            title: 'Appearance',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ThemeController.label(mode),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.r,
                  color: AppTheme.divider(context),
                ),
              ],
            ),
            onTap: () => _showAppearanceSheet(mode),
          ),
        ),
        _DriverMenuTile(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerPrivacyScreen())),
        ),
        _DriverMenuTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerPrivacyScreen())),
        ),
        _DriverMenuTile(
          icon: Icons.info_outline_rounded,
          title: 'About Us',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerAboutScreen())),
        ),
        _DriverMenuTile(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerSupportScreen())),
        ),
      ],
    );
  }

  // ── Sign out section ──────────────────────────────────────────────────────
  Widget _buildSignOutSection(BuildContext context) {
    return _menuGroup(
      context: context,
      title: '',
      tiles: [
        _DriverMenuTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  // ── Appearance sheet ──────────────────────────────────────────────────────
  void _showAppearanceSheet(ThemeMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        final primary = AppTheme.primary(context);
        final divider = AppTheme.divider(context);
        final textPrimary = AppTheme.textPrimary(context);
        final textSecondary = AppTheme.textSecondary(context);
        return Padding(
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
                          ? primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: selected
                            ? primary.withValues(alpha: 0.30)
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
        );
      },
    );
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────
  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Sign Out',
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context)),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary(context),
              height: 1.5),
        ),
        actions: [
          SosButton(
            label: 'Cancel',
            variant: SosButtonVariant.outline,
            fullWidth: false,
            onPressed: () => Navigator.pop(dialogCtx, false),
          ),
          SosButton(
            label: 'Sign Out',
            variant: SosButtonVariant.danger,
            fullWidth: false,
            onPressed: () => Navigator.pop(dialogCtx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  // ── Menu group builder ────────────────────────────────────────────────────
  Widget _menuGroup({
    required BuildContext context,
    required String title,
    required List<Widget> tiles,
  }) {
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
                color: AppTheme.textSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
          ),
        SosCard(
          padding: EdgeInsets.zero,
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MarketplaceBadge — shown when driver also has buyer capability
// ─────────────────────────────────────────────────────────────────────────────
class _MarketplaceBadge extends StatelessWidget {
  const _MarketplaceBadge();

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open the SOS Farmer app on your device to buy crops'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: SosCard(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.storefront_rounded,
                  size: 18.r, color: primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marketplace Access',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Open SOS Farmer app to buy & sell crops',
                    style: TextStyle(
                        fontSize: 11.sp, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 14.r, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DriverMenuTile  — identical layout to _OwnerMenuTile
// ─────────────────────────────────────────────────────────────────────────────
class _DriverMenuTile extends StatelessWidget {
  final IconData  icon;
  final String    title;
  final VoidCallback? onTap;
  final Widget?   trailing;

  const _DriverMenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTheme.textSecondary(context);
    final textColor = AppTheme.textPrimary(context);
    final divider   = AppTheme.divider(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
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
