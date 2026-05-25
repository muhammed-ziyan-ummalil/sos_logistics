// Structural reuse of sosagent_flutter AccountScreen.
// Same: header, profile card, _menuGroup + _OwnerMenuTile pattern,
//       appearance sheet, logout dialog.
// Adapted: uses AppColors/AppLightColors + flutter_screenutil (no AppDesignTokens).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sos_auth/sos_auth.dart';
import '../../../Bloc/OwnerBankDetails/owner_bank_details_cubit.dart';
import '../../../Bloc/OwnerWallet/owner_wallet_cubit.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_controller.dart';
import '../../../utility/shared_preference.dart';
import '../../../Bloc/OwnerProfile/owner_profile_cubit.dart';
import 'owner_about_screen.dart';
import 'owner_analytics_screen.dart';
import 'owner_bank_details_screen.dart';
import 'owner_edit_profile_screen.dart';
import 'owner_privacy_screen.dart';
import 'owner_support_screen.dart';
import 'owner_wallet_screen.dart';

class OwnerAccountScreen extends StatefulWidget {
  const OwnerAccountScreen({super.key});

  @override
  State<OwnerAccountScreen> createState() => _OwnerAccountScreenState();
}

class _OwnerAccountScreenState extends State<OwnerAccountScreen> {
  String _name = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    final info = await AppPrefs.getV2Session();
    if (mounted) {
      setState(() {
        _name = info['name'] ?? '';
        _phone = info['phone'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
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
              child: SingleChildScrollView(
                child: Builder(builder: (context) {
                  final authState = context.watch<AuthCubit>().state;
                  final hasMarketplace = authState is AuthAuthenticated &&
                      (authState.person.hasCap(Capability.buyer) ||
                          authState.person.hasCap(Capability.seller));
                  return Column(
                  children: [
                    if (hasMarketplace) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: const _MarketplaceBadge(),
                      ),
                    ],
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
                );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final surfaceColor =
        isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;

    return Container(
      color: surfaceColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
                bottom: BorderSide(color: dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              Text(
                'Account',
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
    final surfaceColor =
        isDark ? AppColors.surface : AppLightColors.surface;
    final primaryColor =
        isDark ? AppColors.primaryLight : AppLightColors.primary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      color: surfaceColor,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.12),
              border: Border.all(
                  color: primaryColor.withOpacity(0.25), width: 1.5),
            ),
            child: Center(
              child: Text(
                _name.isNotEmpty ? _name[0].toUpperCase() : 'O',
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isNotEmpty ? _name : 'Vehicle Owner',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _phone.isNotEmpty ? _phone : '—',
                  style: TextStyle(
                      fontSize: 13.sp, color: textSecondary),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    'VEHICLE OWNER',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Edit profile button
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Icon(Icons.edit_outlined,
                  size: 18.r, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OwnerProfileCubit(),
          child: const OwnerEditProfileScreen(),
        ),
      ),
    );
    if (result == true) _loadOwnerInfo();
  }

  // ── Services section ──────────────────────────────────────────────────────
  Widget _buildServicesSection(bool isDark) {
    return _menuGroup(
      isDark: isDark,
      title: 'Services',
      tiles: [
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.analytics_outlined,
          title: 'Reporting & Analytics',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerAnalyticsScreen()),
          ),
        ),
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.account_balance_wallet_outlined,
          title: 'My Wallet',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => OwnerWalletCubit()..fetchWallet(),
                child: const OwnerWalletScreen(),
              ),
            ),
          ),
        ),
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.account_balance_outlined,
          title: 'Bank Details',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => OwnerBankDetailsCubit()..fetchDetails(),
                child: const OwnerBankDetailsScreen(),
              ),
            ),
          ),
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
        // Appearance — same pattern as agent app
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (_, mode, __) => _OwnerMenuTile(
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
                          : AppLightColors.textSecondary),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.chevron_right_rounded,
                    size: 18.r,
                    color: isDark
                        ? AppColors.divider
                        : AppLightColors.divider),
              ],
            ),
            onTap: () => _showAppearanceSheet(isDark, mode),
          ),
        ),
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerPrivacyScreen()),
          ),
        ),
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerPrivacyScreen()),
          ),
        ),
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.info_outline_rounded,
          title: 'About Us',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerAboutScreen()),
          ),
        ),
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.support_agent_outlined,
          title: 'Support',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerSupportScreen()),
          ),
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
        _OwnerMenuTile(
          isDark: isDark,
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          onTap: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  // ── Appearance bottom sheet — identical UX to agent app ───────────────────
  void _showAppearanceSheet(bool isDark, ThemeMode current) {
    final surfaceColor =
        isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primaryColor =
        isDark ? AppColors.primaryLight : AppLightColors.primary;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20.r))),
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
                    color: dividerColor,
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
                style:
                    TextStyle(fontSize: 13.sp, color: textSecondary)),
            SizedBox(height: 20.h),
            ...[ThemeMode.light, ThemeMode.dark, ThemeMode.system]
                .map((mode) {
              final isSelected = current == mode;
              return GestureDetector(
                onTap: () {
                  themeController.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor.withOpacity(0.30)
                          : dividerColor,
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
                        color: isSelected
                            ? primaryColor
                            : textSecondary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          ThemeController.label(mode),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? primaryColor
                                : textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_rounded,
                            size: 18.r, color: primaryColor),
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

  // ── Logout dialog — same logic as agent app showLogoutPopup ───────────────
  Future<void> _showLogoutDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surface : AppLightColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text('Sign Out',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimary
                    : AppLightColors.textPrimary)),
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  // ── Shared menu group builder ─────────────────────────────────────────────
  Widget _menuGroup({
    required bool isDark,
    required String title,
    required List<Widget> tiles,
  }) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final cardColor =
        isDark ? AppColors.surface : AppLightColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
// _MarketplaceBadge — shown when owner also has buyer or seller capability
// ─────────────────────────────────────────────────────────────────────────────
class _MarketplaceBadge extends StatelessWidget {
  const _MarketplaceBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppLightColors.surface;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Open the SOS Farmer app on your device to buy & sell crops'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
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
// _OwnerMenuTile
// Logistics-adapted clone of sosagent_flutter MinimalOptionTile.
// Same layout, same intent — uses AppColors instead of AppDesignTokens.
// ─────────────────────────────────────────────────────────────────────────────
class _OwnerMenuTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _OwnerMenuTile({
    required this.isDark,
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final textColor =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final cardColor =
        isDark ? AppColors.surface : AppLightColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
              bottom: BorderSide(color: dividerColor, width: 0.8)),
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
                Icon(Icons.chevron_right_rounded,
                    size: 18.r, color: dividerColor),
          ],
        ),
      ),
    );
  }
}
