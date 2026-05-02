import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_theme.dart';

class OwnerAboutScreen extends StatelessWidget {
  const OwnerAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: BackButton(
            color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
        title: Text('About Us',
            style: TextStyle(color: textPrimary, fontSize: 17.sp)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBanner(isDark: isDark),
            SizedBox(height: 24.h),
            _MissionCard(isDark: isDark),
            SizedBox(height: 20.h),
            _EcosystemSection(isDark: isDark),
            SizedBox(height: 20.h),
            _LogisticsRoleSection(isDark: isDark),
            SizedBox(height: 20.h),
            _ValuesSection(isDark: isDark),
            SizedBox(height: 20.h),
            _VersionCard(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  const _HeroBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B3D91), Color(0xFF1A5DC8)],
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
                    color: Colors.white.withOpacity(0.15),
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
                  color: Colors.white.withOpacity(0.85),
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
  final bool isDark;
  const _MissionCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
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
                      color: textPrimary)),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'SOSSSS was founded to solve the critical inefficiencies in Nigeria\'s agricultural supply chain. Farmers lose up to 40% of their produce post-harvest due to poor logistics, lack of reliable buyers, and inefficient distribution networks.',
            style: TextStyle(
                fontSize: 13.sp, color: textSecondary, height: 1.6),
          ),
          SizedBox(height: 8.h),
          Text(
            'Our platform bridges this gap by connecting farmers, buyers, logistics operators, and agents on a single, technology-driven ecosystem.',
            style: TextStyle(
                fontSize: 13.sp, color: textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── Ecosystem section ────────────────────────────────────────────────────────

class _EcosystemSection extends StatelessWidget {
  final bool isDark;
  const _EcosystemSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

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
          color: const Color(0xFF16A34A),
          title: 'SOSSSS Marketplace',
          description:
              'A digital marketplace connecting agricultural producers (sellers/farmers) directly with buyers (retailers, processors, exporters). Supports product listings, price negotiation, and order management.',
          isDark: isDark,
        ),
        SizedBox(height: 10.h),
        _EcoPillar(
          icon: Icons.people_rounded,
          color: const Color(0xFF0B3D91),
          title: 'Agent Network',
          description:
              'A three-tier agent system (Platinum, Gold, Silver) empowering local entrepreneurs to operate as marketplace facilitators. Agents build networks of buyers and sellers, earning commissions on transactions within their territory.',
          isDark: isDark,
        ),
        SizedBox(height: 10.h),
        _EcoPillar(
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF1A5DC8),
          title: 'SOSSSS Logistics',
          description:
              'The logistics arm that powers physical delivery of goods. Vehicle owners register their fleets, onboard drivers, and fulfill delivery orders generated by the marketplace. You are part of this critical layer.',
          isDark: isDark,
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
  final bool isDark;
  final bool highlighted;

  const _EcoPillar({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isDark,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.06) : cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: highlighted ? color.withOpacity(0.3) : dividerColor,
            width: highlighted ? 1.5 : 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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
                              color: textPrimary)),
                    ),
                    if (highlighted)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
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
                        fontSize: 12.sp, color: textSecondary, height: 1.5)),
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
  final bool isDark;
  const _LogisticsRoleSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

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
                isDark: isDark,
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
  final bool isDark;
  const _RoleItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
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
                        color: textPrimary)),
                SizedBox(height: 3.h),
                Text(description,
                    style: TextStyle(
                        fontSize: 12.sp, color: textSecondary, height: 1.4)),
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
  final bool isDark;
  const _ValuesSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;

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
                padding: EdgeInsets.only(right: v.$1 != values.last.$1 ? 8.w : 0),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: dividerColor, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Icon(v.$1, color: accentColor, size: 22.r),
                      SizedBox(height: 6.h),
                      Text(v.$2,
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppLightColors.textPrimary)),
                      SizedBox(height: 4.h),
                      Text(v.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppLightColors.textSecondary,
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
  final bool isDark;
  const _VersionCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_rounded, color: accentColor, size: 16.r),
          SizedBox(width: 8.w),
          Text(
            'SOSSSS Logistics v1.0.0',
            style: TextStyle(
                fontSize: 12.sp,
                color: textSecondary,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8.w),
          Text('·', style: TextStyle(color: textSecondary)),
          SizedBox(width: 8.w),
          Text('© 2025 SOSSSS',
              style: TextStyle(fontSize: 12.sp, color: textSecondary)),
        ],
      ),
    );
  }
}
