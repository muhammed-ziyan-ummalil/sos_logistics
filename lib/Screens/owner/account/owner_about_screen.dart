import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

class OwnerAboutScreen extends StatelessWidget {
  const OwnerAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: const SosAppBar(title: 'About Us'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(),
            SizedBox(height: 24.h),
            _MissionCard(),
            SizedBox(height: 20.h),
            _EcosystemSection(),
            SizedBox(height: 20.h),
            _LogisticsRoleSection(),
            SizedBox(height: 20.h),
            _ValuesSection(),
            SizedBox(height: 20.h),
            _VersionCard(),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDark = AppDesignTokens.lightPrimaryDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 26.r),
                ),
                SizedBox(width: 14.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOSSSS',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        )),
                    Text('Logistics Platform',
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Connecting Nigeria\'s agricultural supply chain through technology-driven logistics.',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mission card ─────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);

    return SosCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: accentColor, size: 18.r),
              SizedBox(width: 8.w),
              Text('Our Mission',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context))),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'SOSSSS was founded to solve the critical inefficiencies in Nigeria\'s agricultural supply chain. Farmers lose up to 40% of their produce post-harvest due to poor logistics, lack of reliable buyers, and inefficient distribution networks.',
            style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondary(context),
                height: 1.6),
          ),
          SizedBox(height: 8.h),
          Text(
            'Our platform bridges this gap by connecting farmers, buyers, logistics operators, and agents on a single, technology-driven ecosystem.',
            style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondary(context),
                height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── Ecosystem section ────────────────────────────────────────────────────────

class _EcosystemSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hub_rounded, color: accentColor, size: 16.r),
            SizedBox(width: 6.w),
            Text('THE SOSSSS ECOSYSTEM',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8)),
          ],
        ),
        SizedBox(height: 14.h),
        _EcoPillar(
          icon: Icons.store_rounded,
          color: AppDesignTokens.success,
          title: 'SOSSSS Marketplace',
          description:
              'A digital marketplace connecting agricultural producers (sellers/farmers) directly with buyers (retailers, processors, exporters). Supports product listings, price negotiation, and order management.',
        ),
        SizedBox(height: 10.h),
        _EcoPillar(
          icon: Icons.people_rounded,
          color: AppDesignTokens.lightAccent,
          title: 'Agent Network',
          description:
              'A three-tier agent system (Platinum, Gold, Silver) empowering local entrepreneurs to operate as marketplace facilitators. Agents build networks of buyers and sellers, earning commissions on transactions within their territory.',
        ),
        SizedBox(height: 10.h),
        _EcoPillar(
          icon: Icons.local_shipping_rounded,
          color: primary,
          title: 'SOSSSS Logistics',
          description:
              'The logistics arm that powers physical delivery of goods. Vehicle owners register their fleets, onboard drivers, and fulfill delivery orders generated by the marketplace. You are part of this critical layer.',
          highlighted: true,
        ),
      ],
    );
  }
}

class _EcoPillar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool highlighted;

  const _EcoPillar({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.06) : scheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: highlighted
                ? color.withValues(alpha: 0.3)
                : scheme.outline,
            width: highlighted ? 1.5 : 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context))),
                    ),
                    if (highlighted)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text('YOU ARE HERE',
                            style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(description,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary(context),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logistics role section ───────────────────────────────────────────────────

class _LogisticsRoleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_pin_circle_rounded, color: accentColor, size: 16.r),
            SizedBox(width: 6.w),
            Text('YOUR ROLE AS OWNER',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8)),
          ],
        ),
        SizedBox(height: 14.h),
        ...([
          (Icons.group_add_rounded, 'Register & Manage Drivers',
              'Add drivers to your fleet, verify their documents, and control their active status on the platform.'),
          (Icons.directions_car_rounded, 'Fleet Management',
              'Register vehicles, track their assignment status, and maintain insurance and documentation records.'),
          (Icons.local_shipping_rounded, 'Fulfill Deliveries',
              'Your fleet receives and fulfills delivery orders from buyers and sellers on the SOSSSS Marketplace.'),
          (Icons.account_balance_wallet_rounded, 'Earnings & Payouts',
              'Earn delivery fees credited to your SOSSSS wallet. Request withdrawals to your registered bank account at any time.'),
        ]).map((item) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _RoleItem(
                icon: item.$1,
                title: item.$2,
                description: item.$3,
              ),
            )),
      ],
    );
  }
}

class _RoleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _RoleItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SosCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: primary, size: 16.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context))),
                SizedBox(height: 3.h),
                Text(description,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary(context),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Values section ───────────────────────────────────────────────────────────

class _ValuesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);

    final values = [
      (Icons.handshake_rounded, 'Trust', 'Every transaction is transparent and every payout is reliable.'),
      (Icons.speed_rounded, 'Speed', 'Efficient delivery coordination that keeps supply chains moving.'),
      (Icons.nature_rounded, 'Impact', 'Reducing food waste and empowering farmers across Nigeria.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stars_rounded, color: accentColor, size: 16.r),
            SizedBox(width: 6.w),
            Text('OUR VALUES',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8)),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: values.map((v) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: v.$1 != values.last.$1 ? 8.w : 0),
                child: SosCard(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    children: [
                      Icon(v.$1, color: accentColor, size: 22.r),
                      SizedBox(height: 6.h),
                      Text(v.$2,
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context))),
                      SizedBox(height: 4.h),
                      Text(v.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondary(context),
                              height: 1.4)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Version card ─────────────────────────────────────────────────────────────

class _VersionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);

    return SosCard(
      padding: EdgeInsets.all(16.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_rounded, color: accentColor, size: 16.r),
          SizedBox(width: 8.w),
          Text(
            'SOSSSS Logistics v1.0.0',
            style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8.w),
          Text('·',
              style: TextStyle(color: AppTheme.textSecondary(context))),
          SizedBox(width: 8.w),
          Text('© 2025 SOSSSS',
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}
