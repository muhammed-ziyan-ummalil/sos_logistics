import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Bloc/Fleet/fleet_dashboard_cubit.dart';
import '../../Bloc/Fleet/fleet_dashboard_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../utility/shared_preference.dart';
import 'delivery/delivery_feed_screen.dart';
import 'delivery/my_quotes_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  String _ownerName = '';

  @override
  void initState() {
    super.initState();
    context.read<FleetDashboardCubit>().fetchDashboard();
    _loadName();
  }

  Future<void> _loadName() async {
    final info = await AppPrefs.getV2Session();
    if (mounted) setState(() => _ownerName = info['name'] ?? '');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            color: surfaceColor,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 12.h),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: textSecondary,
                                letterSpacing: 0.1),
                          ),
                          Text(
                            _ownerName.isNotEmpty ? _ownerName : 'Owner',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle),
                          ),
                          SizedBox(width: 5.w),
                          Text('LIVE',
                              style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                    BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
                      builder: (_, s) => IconButton(
                        icon: Icon(Icons.refresh_rounded,
                            color: textSecondary, size: 20.r),
                        onPressed: s is FleetDashboardLoading
                            ? null
                            : () => context
                                .read<FleetDashboardCubit>()
                                .fetchDashboard(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
              builder: (ctx, state) {
                if (state is FleetDashboardInitial ||
                    state is FleetDashboardLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2.5),
                  );
                }
                if (state is FleetDashboardError) {
                  return _ErrorView(
                    message: state.message,
                    isDark: isDark,
                    onRetry: () => context
                        .read<FleetDashboardCubit>()
                        .fetchDashboard(),
                  );
                }
                if (state is FleetDashboardLoaded) {
                  return _HomeBody(state: state, isDark: isDark);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home body ────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final FleetDashboardLoaded state;
  final bool isDark;
  const _HomeBody({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;

    return RefreshIndicator(
      color: accentColor,
      backgroundColor: cardColor,
      onRefresh: () => context.read<FleetDashboardCubit>().fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // Stats cards
            _StatsRow(summary: state.summary, isDark: isDark),
            SizedBox(height: 20.h),

            // Driver snapshot
            if (state.drivers.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _DriverSnapshotSection(
                    drivers: state.drivers, isDark: isDark),
              ),
            if (state.drivers.isNotEmpty) SizedBox(height: 20.h),

            // Active deliveries — always show (empty state if none)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _ActiveDeliveriesSection(
                  deliveries: state.activeDeliveries, isDark: isDark),
            ),
            SizedBox(height: 20.h),

            // Alerts (only when present)
            if (state.inactiveAlerts.isNotEmpty ||
                state.unassignedAlerts.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _AlertsSection(
                  inactive: state.inactiveAlerts,
                  unassigned: state.unassignedAlerts,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: 20.h),
            ],

            // Performance
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _PerformanceSection(
                  performance: state.performance, isDark: isDark),
            ),
            SizedBox(height: 20.h),

            // Quick links to Manage
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _ManageShortcuts(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  final bool isDark;
  const _StatsRow({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final totalDrivers = summary['total_drivers']?.toString() ?? '0';
    final activeDrivers = summary['active_drivers']?.toString() ?? '0';
    final onlineDrivers = summary['online_drivers']?.toString() ?? '0';
    final activeDeliveries = summary['active_deliveries']?.toString() ?? '0';
    final earnings = summary['today_earnings'];
    final earningsStr = earnings != null
        ? '₹${_fmtNum(double.tryParse(earnings.toString()) ?? 0)}'
        : '₹0';
    final primaryColor =
        isDark ? AppColors.primaryLight : AppLightColors.primary;
    final warningColor = isDark ? AppColors.warning : AppLightColors.warning;

    final cards = [
      _StatData(
          icon: Icons.people_rounded,
          label: 'Total\nDrivers',
          value: totalDrivers,
          color: primaryColor),
      _StatData(
          icon: Icons.check_circle_rounded,
          label: 'Active\nDrivers',
          value: activeDrivers,
          color: AppColors.success),
      _StatData(
          icon: Icons.wifi_rounded,
          label: 'Online\nNow',
          value: onlineDrivers,
          color: isDark ? AppColors.accent : AppLightColors.accent),
      _StatData(
          icon: Icons.local_shipping_rounded,
          label: 'Live\nDeliveries',
          value: activeDeliveries,
          color: warningColor),
      _StatData(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Today\'s\nEarnings',
          value: earningsStr,
          color: AppColors.success),
    ];

    return SizedBox(
      height: 110.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: cards.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: 10.w),
          child: _StatCard(data: cards[i], isDark: isDark),
        ),
      ),
    );
  }

  String _fmtNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatData(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool isDark;
  const _StatCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Stack(
        children: [
          Container(
            width: 112.w,
            padding: EdgeInsets.fromLTRB(12.r, 16.r, 12.r, 12.r),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: dividerColor, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Icon(data.icon, color: data.color, size: 14.r),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.value,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    SizedBox(height: 2.h),
                    Text(data.label,
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 9.sp,
                            height: 1.3)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 3.h, color: data.color),
          ),
        ],
      ),
    );
  }
}

// ─── Active deliveries section ────────────────────────────────────────────────

class _ActiveDeliveriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> deliveries;
  final bool isDark;
  const _ActiveDeliveriesSection(
      {required this.deliveries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final warningColor = isDark ? AppColors.warning : AppLightColors.warning;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.local_shipping_rounded,
            label: 'ACTIVE DELIVERIES',
            color: warningColor),
        SizedBox(height: 10.h),
        if (deliveries.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: dividerColor, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, color: dividerColor, size: 20.r),
                SizedBox(width: 10.w),
                Text('No active deliveries right now',
                    style: TextStyle(
                        color: textSecondary, fontSize: 13.sp)),
              ],
            ),
          )
        else
          ...deliveries.map((d) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _DeliveryTile(delivery: d, isDark: isDark),
              )),
      ],
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final bool isDark;
  const _DeliveryTile({required this.delivery, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final warningColor = isDark ? AppColors.warning : AppLightColors.warning;

    final id = delivery['delivery_id']?.toString() ??
        delivery['id']?.toString() ??
        '—';
    final driverName =
        (delivery['driver'] as Map?)?['name'] as String? ??
            delivery['driver_name'] as String? ??
            '—';
    final status = delivery['status'] as String? ?? '—';
    final eta = delivery['eta'] as String? ??
        delivery['estimated_arrival'] as String?;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.local_shipping_rounded,
                color: warningColor, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#$id',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(driverName,
                    style: TextStyle(
                        color: textSecondary, fontSize: 11.sp)),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: status, isDark: isDark),
                if (eta != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 10.r, color: textSecondary),
                      SizedBox(width: 3.w),
                      Text(eta,
                          style: TextStyle(
                              color: textSecondary, fontSize: 10.sp)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alerts section ───────────────────────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  final List<Map<String, dynamic>> inactive;
  final List<Map<String, dynamic>> unassigned;
  final bool isDark;
  const _AlertsSection(
      {required this.inactive,
      required this.unassigned,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final warningColor = isDark ? AppColors.warning : AppLightColors.warning;
    final errorColor = isDark ? AppColors.error : AppLightColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.warning_amber_rounded,
            label: 'FLEET ALERTS',
            color: warningColor),
        SizedBox(height: 10.h),
        ...inactive.map((d) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _AlertTile(
                icon: Icons.bedtime_rounded,
                message:
                    '${d['name'] ?? 'Driver'} has been inactive for 3+ days.',
                color: warningColor,
              ),
            )),
        ...unassigned.map((d) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _AlertTile(
                icon: Icons.local_shipping_rounded,
                message:
                    '${d['name'] ?? 'Driver'} is active but has no vehicle assigned.',
                color: errorColor,
              ),
            )),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _AlertTile(
      {required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Performance section ──────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  final Map<String, dynamic> performance;
  final bool isDark;
  const _PerformanceSection(
      {required this.performance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final acceptanceRate =
        (performance['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
    final missedJobs = performance['missed_jobs'] as int? ?? 0;
    final completedJobs = performance['completed_jobs'] as int? ?? 0;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final errorColor = isDark ? AppColors.error : AppLightColors.error;
    final rateColor = acceptanceRate >= 80
        ? AppColors.success
        : acceptanceRate >= 50
            ? (isDark ? AppColors.warning : AppLightColors.warning)
            : errorColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.bar_chart_rounded,
            label: 'PERFORMANCE',
            color: accentColor),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _PerfCard(
                label: 'Acceptance Rate',
                value: '${acceptanceRate.toStringAsFixed(1)}%',
                icon: Icons.thumb_up_rounded,
                color: rateColor,
                subLabel: 'fleet average',
                isDark: isDark,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _PerfCard(
                label: 'Missed Jobs',
                value: missedJobs.toString(),
                icon: Icons.cancel_rounded,
                color: missedJobs == 0 ? AppColors.success : errorColor,
                subLabel: 'this month',
                isDark: isDark,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _PerfCard(
                label: 'Completed',
                value: completedJobs.toString(),
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                subLabel: 'this month',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerfCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subLabel;
  final bool isDark;
  const _PerfCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500)),
          Text(subLabel,
              style: TextStyle(
                  color: textSecondary, fontSize: 9.sp)),
        ],
      ),
    );
  }
}

// ─── Manage shortcuts ─────────────────────────────────────────────────────────

class _ManageShortcuts extends StatelessWidget {
  final bool isDark;
  const _ManageShortcuts({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.grid_view_rounded,
            label: 'QUICK ACTIONS',
            color: accentColor),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.v2AddDriver),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: accentColor.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person_add_rounded,
                          color: accentColor, size: 22.r),
                      SizedBox(height: 6.h),
                      Text('Add Driver',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: accentColor)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.v2VehicleList),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: accentColor.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.directions_car_rounded,
                          color: accentColor, size: 22.r),
                      SizedBox(height: 6.h),
                      Text('Add Vehicle',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: accentColor)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.v2DriverList),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: accentColor.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.list_rounded,
                          color: accentColor, size: 22.r),
                      SizedBox(height: 6.h),
                      Text('All Drivers',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: accentColor)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryFeedScreen()),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping,
                          color: AppColors.success, size: 22.r),
                      SizedBox(height: 6.h),
                      Text('Available Deliveries',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyQuotesScreen()),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long,
                          color: Colors.blue, size: 22.r),
                      SizedBox(height: 6.h),
                      Text('My Quotes',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14.r),
        SizedBox(width: 6.w),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;
  const _StatusBadge({required this.status, required this.isDark});

  Color _color(String s) => switch (s) {
        'active' || 'completed' || 'delivered' => AppColors.success,
        'suspended' || 'disabled' || 'rejected' || 'failed' =>
          isDark ? AppColors.error : AppLightColors.error,
        'in_progress' || 'picked_up' =>
          isDark ? AppColors.warning : AppLightColors.warning,
        _ => isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
      };

  String _label(String s) => switch (s) {
        'active' => 'ACTIVE',
        'pending_admin' => 'CREATED',
        'suspended' => 'SUSPENDED',
        'disabled' => 'DISABLED',
        'in_progress' => 'IN PROGRESS',
        'picked_up' => 'PICKED UP',
        'delivered' => 'DELIVERED',
        _ => s.toUpperCase().replaceAll('_', ' '),
      };

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(_label(status),
          style: TextStyle(
              color: c, fontSize: 9.sp, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Driver snapshot ──────────────────────────────────────────────────────────

class _DriverSnapshotSection extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  final bool isDark;
  const _DriverSnapshotSection(
      {required this.drivers, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final toShow = drivers.length > 3 ? drivers.sublist(0, 3) : drivers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
                icon: Icons.people_rounded,
                label: 'DRIVER SNAPSHOT',
                color: accentColor),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.v2DriverList),
              child: Text(
                'See all',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        ...toShow.map((d) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _DriverSnapshotTile(driver: d, isDark: isDark),
            )),
      ],
    );
  }
}

class _DriverSnapshotTile extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool isDark;
  const _DriverSnapshotTile(
      {required this.driver, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primaryColor =
        isDark ? AppColors.primaryLight : AppLightColors.primary;

    final name = driver['name'] as String? ?? '—';
    final status = driver['status'] as String? ?? '';
    final isOnline = driver['is_online'] == true ||
        driver['is_online'] == 1 ||
        driver['is_online'] == '1';
    final vehicle = driver['vehicle'] as Map<String, dynamic>?;
    final plate = vehicle?['reg_number'] as String? ?? 'No vehicle';
    final vehicleType = vehicle?['type'] as String?;

    final statusColor = switch (status) {
      'active' => AppColors.success,
      'suspended' || 'disabled' =>
        isDark ? AppColors.error : AppLightColors.error,
      _ => textSecondary,
    };

    return GestureDetector(
      onTap: () {
        final id = driver['id']?.toString() ??
            driver['driver_id']?.toString() ??
            '';
        if (id.isEmpty) return;
        Navigator.pushNamed(
          context,
          AppRoutes.v2DriverDetail,
          arguments: {'driver_id': id, 'driver': driver},
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: dividerColor, width: 0.8),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: primaryColor.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : dividerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Container(
                        width: 5.r,
                        height: 5.r,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_rounded,
                          size: 10.r, color: textSecondary),
                      SizedBox(width: 3.w),
                      Flexible(
                        child: Text(
                          plate,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (vehicleType != null)
                    Text(
                      vehicleType.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.sp, color: textSecondary),
                    ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_right_rounded,
                color: dividerColor, size: 16.r),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorView(
      {required this.message, required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final errorColor = isDark ? AppColors.error : AppLightColors.error;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: errorColor, size: 28.r),
            ),
            SizedBox(height: 16.h),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textSecondary, fontSize: 13.sp)),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
