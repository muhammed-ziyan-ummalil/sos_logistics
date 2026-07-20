// Structural reuse of sosagent_flutter AccountScreen.
// Same: header, profile card, _menuGroup + _OwnerMenuTile pattern,
//       appearance sheet, logout dialog.
// Phase G: migrated to AppTheme.x(context) / widget library.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sos_auth/sos_auth.dart';
import '../../../Bloc/OwnerBankDetails/owner_bank_details_cubit.dart';
import '../../../Bloc/OwnerKyc/owner_kyc_cubit.dart';
import '../../../Bloc/OwnerWallet/owner_wallet_cubit.dart';
import '../../../Bloc/OwnerWithdrawals/owner_withdrawals_cubit.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_controller.dart';
import '../../../utility/api_service.dart';
import '../../../utility/shared_preference.dart';
import '../../../Bloc/OwnerProfile/owner_profile_cubit.dart';
import '../../../widgets/widgets.dart';
import 'owner_about_screen.dart';
import 'owner_bank_details_screen.dart';
import 'owner_edit_profile_screen.dart';
import 'owner_kyc_screen.dart';
import 'owner_privacy_screen.dart';
import 'owner_support_screen.dart';
import 'owner_wallet_screen.dart';
import 'owner_withdrawals_screen.dart';

class OwnerAccountScreen extends StatefulWidget {
  const OwnerAccountScreen({super.key});

  @override
  State<OwnerAccountScreen> createState() => _OwnerAccountScreenState();
}

class _OwnerAccountScreenState extends State<OwnerAccountScreen> {
  String _name = '';
  String _phone = '';
  String _kycStatus = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
    _loadKycStatus();
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

  Future<void> _loadKycStatus() async {
    final res = await ApiServiceUnified.instance.getOwnerKycDetails();
    if (res['status'] == 'success' && mounted) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() => _kycStatus = (data['kyc_status'] ?? 'none') as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            _buildHeader(context),
            _buildProfileCard(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    children: [
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
                  ),
              ),
            ),
          ],
        ),
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
            border: Border(
                bottom: BorderSide(color: AppTheme.divider(context), width: 1)),
          ),
          child: Row(
            children: [
              Text(
                'Account',
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
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: AppTheme.surface(context),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
              border: Border.all(
                  color: primary.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Center(
              child: Text(
                _name.isNotEmpty ? _name[0].toUpperCase() : 'O',
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: primary),
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
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _phone.isNotEmpty ? _phone : '—',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary(context)),
                ),
                SizedBox(height: 4.h),
                const SosChip(label: 'VEHICLE OWNER', tone: SosTone.success),
              ],
            ),
          ),
          // Edit profile button
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.edit_outlined,
                  size: 18.r, color: primary),
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
    if (result == true && mounted) _loadOwnerInfo();
  }

  // ── Services section ──────────────────────────────────────────────────────
  Widget _buildServicesSection(BuildContext context) {
    return _menuGroup(
      context: context,
      title: 'Services',
      tiles: [
        _OwnerMenuTile(
          icon: Icons.verified_user_outlined,
          title: 'KYC Verification',
          trailing: _kycStatus.isEmpty ? null : _kycStatusTrailing(context),
          onTap: _openKyc,
        ),
        _OwnerMenuTile(
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
          icon: Icons.payments_outlined,
          title: 'Withdraw',
          onTap: _openWithdrawals,
        ),
        _OwnerMenuTile(
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

  // ── KYC ───────────────────────────────────────────────────────────────────
  Widget _kycStatusTrailing(BuildContext context) {
    String label;
    Color color;
    switch (_kycStatus) {
      case 'approved':
        label = 'Approved';
        color = AppDesignTokens.success;
        break;
      case 'pending':
        label = 'Pending';
        color = AppDesignTokens.warning;
        break;
      case 'rejected':
        label = 'Rejected';
        color = AppTheme.error(context);
        break;
      default:
        label = 'Required';
        color = AppTheme.textSecondary(context);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(width: 4.w),
        Icon(Icons.chevron_right_rounded,
            size: 18.r, color: AppTheme.divider(context)),
      ],
    );
  }

  Future<void> _openKyc() async {
    // Screen-owned fetch: OwnerKycScreen.initState calls fetchDetails(),
    // so the provider does NOT pre-fetch (avoids a double load).
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OwnerKycCubit(),
          child: const OwnerKycScreen(),
        ),
      ),
    );
    if (mounted) _loadKycStatus();
  }

  // ── Withdraw / earnings ────────────────────────────────────────────────────
  Future<void> _openWithdrawals() async {
    // Person-level KYC gate — server enforces too; this is the friendly prompt.
    final kycRes = await ApiServiceUnified.instance.getOwnerKycDetails();
    if (kycRes['status'] == 'success') {
      final status =
          ((kycRes['data'] as Map<String, dynamic>?)?['kyc_status'] ?? 'none')
              as String;
      // Keep the Services tile badge in sync with the freshly fetched status.
      if (mounted && status != _kycStatus) {
        setState(() => _kycStatus = status);
      }
      if (status != 'approved') {
        if (!mounted) return;
        final goToKyc = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('KYC Required'),
            content: Text(status == 'pending'
                ? 'Your KYC is under review. Withdrawals unlock once it is approved.'
                : 'Complete KYC verification to enable wallet withdrawals.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Later')),
              if (status != 'pending')
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Complete KYC')),
            ],
          ),
        );
        if (goToKyc == true && mounted) _openKyc();
        return;
      }
    }
    // Resolve bank-details presence up front so the screen can nudge the owner
    // to add them first when missing.
    bool hasBankDetails = true;
    final res = await ApiServiceUnified.instance.getOwnerBankDetails();
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final bank = data['bank'];
      hasBankDetails = bank is Map &&
          (bank['account_number'] != null || bank['bank_name'] != null);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OwnerWithdrawalsCubit()..fetchWithdrawals(),
          child: OwnerWithdrawalsScreen(hasBankDetails: hasBankDetails),
        ),
      ),
    );
  }

  // ── App section ───────────────────────────────────────────────────────────
  Widget _buildAppSection(BuildContext context) {
    return _menuGroup(
      context: context,
      title: 'App',
      tiles: [
        // Appearance — same pattern as agent app
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (_, mode, __) => _OwnerMenuTile(
            icon: Icons.brightness_medium_outlined,
            title: 'Appearance',
            trailing: Builder(builder: (ctx) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ThemeController.label(mode),
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary(ctx)),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.chevron_right_rounded,
                    size: 18.r,
                    color: AppTheme.divider(ctx)),
              ],
            )),
            onTap: () => _showAppearanceSheet(context, mode),
          ),
        ),
        _OwnerMenuTile(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerPrivacyScreen()),
          ),
        ),
        _OwnerMenuTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerPrivacyScreen()),
          ),
        ),
        _OwnerMenuTile(
          icon: Icons.info_outline_rounded,
          title: 'About Us',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerAboutScreen()),
          ),
        ),
        _OwnerMenuTile(
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
  Widget _buildSignOutSection(BuildContext context) {
    return _menuGroup(
      context: context,
      title: '',
      tiles: [
        _OwnerMenuTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          onTap: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  // ── Appearance bottom sheet — identical UX to agent app ───────────────────
  void _showAppearanceSheet(BuildContext context, ThemeMode current) {
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
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
                    color: AppTheme.divider(ctx),
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Appearance',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(ctx),
                    letterSpacing: -0.2)),
            Text('Choose how the app looks on your device.',
                style:
                    TextStyle(fontSize: 13.sp, color: AppTheme.textSecondary(ctx))),
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
                        ? primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected
                          ? primary.withValues(alpha: 0.30)
                          : AppTheme.divider(ctx),
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
                            ? primary
                            : AppTheme.textSecondary(ctx),
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
                                ? primary
                                : AppTheme.textPrimary(ctx),
                          ),
                        ),
                      ),
                      if (isSelected)
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

  // ── Logout dialog — same logic as agent app showLogoutPopup ───────────────
  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text('Sign Out',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(ctx))),
        content: Text(
          'Are you sure you want to sign out of your account?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary(ctx),
              height: 1.5),
        ),
        actions: [
          SosButton(
            label: 'Cancel',
            variant: SosButtonVariant.outline,
            fullWidth: false,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          SosButton(
            label: 'Sign Out',
            variant: SosButtonVariant.danger,
            fullWidth: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  // ── Shared menu group builder ─────────────────────────────────────────────
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
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
        Container(
            color: AppTheme.surface(context),
            child: Column(children: tiles)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OwnerMenuTile
// Logistics-adapted clone of sosagent_flutter MinimalOptionTile.
// Phase G: theme-aware via AppTheme.x(context).
// ─────────────────────────────────────────────────────────────────────────────
class _OwnerMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _OwnerMenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(
              bottom: BorderSide(
                  color: AppTheme.divider(context), width: 0.8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: AppTheme.textSecondary(context)),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary(context)),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    size: 18.r, color: AppTheme.divider(context)),
          ],
        ),
      ),
    );
  }
}
