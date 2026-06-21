import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  static const _roles = [
    _RoleOption(
      role: UserRole.owner,
      icon: Icons.admin_panel_settings_rounded,
      title: 'Fleet Owner',
      subtitle: 'Manage your vehicles, drivers, and track earnings.',
    ),
    _RoleOption(
      role: UserRole.driver,
      icon: Icons.local_shipping_rounded,
      title: 'Driver',
      subtitle: 'Accept delivery jobs and complete shipments.',
    ),
  ];

  void _onContinue() {
    if (_selectedRole == null) return;
    Navigator.pushNamed(context, AppRoutes.login, arguments: _selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48.h),
              const Center(
                child: SosLogoMark(size: 72),
              ),
              SizedBox(height: 32.h),
              Text(
                'Choose Your Role',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'How would you like to use SOSSSS Logistics?',
                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14.sp),
              ),
              SizedBox(height: 32.h),
              ...List.generate(_roles.length, (i) {
                final opt = _roles[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: _RoleCard(
                    option: opt,
                    selected: _selectedRole == opt.role,
                    onTap: () => setState(() => _selectedRole = opt.role),
                  ),
                );
              }),
              const Spacer(),
              SosButton(
                label: 'Continue',
                onPressed: _selectedRole == null ? null : _onContinue,
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final String role;
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoleOption({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary(context).withValues(alpha: 0.12) : AppTheme.card(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppTheme.primary(context) : AppTheme.divider(context),
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary(context) : AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                option.icon,
                color: selected ? Colors.white : AppTheme.textSecondary(context),
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    option.subtitle,
                    style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primary(context),
                      size: 24.r,
                      key: const ValueKey(true),
                    )
                  : Icon(
                      Icons.circle_outlined,
                      color: AppTheme.divider(context),
                      size: 24.r,
                      key: const ValueKey(false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
