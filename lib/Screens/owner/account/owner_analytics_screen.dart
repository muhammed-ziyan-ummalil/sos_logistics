import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/Fleet/fleet_dashboard_cubit.dart';
import '../../../Bloc/Fleet/fleet_dashboard_state.dart';
import '../../../core/app_theme.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  String _selectedFilter = 'Today';
  static const _filters = ['Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    final s = context.read<FleetDashboardCubit>().state;
    if (s is FleetDashboardInitial) {
      context.read<FleetDashboardCubit>().fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: BackButton(
            color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
        title: Text('Reporting & Analytics',
            style: TextStyle(color: textPrimary, fontSize: 17.sp)),
        centerTitle: true,
      ),
      body: BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
        builder: (ctx, state) {
          if (state is FleetDashboardInitial || state is FleetDashboardLoading) {
            return Center(
                child: CircularProgressIndicator(
                    color: accentColor, strokeWidth: 2.5));
          }

          Map<String, dynamic> summary = {};
          List<Map<String, dynamic>> drivers = [];
          List<Map<String, dynamic>> deliveries = [];
          Map<String, dynamic> performance = {};

          if (state is FleetDashboardLoaded) {
            summary = state.summary;
            drivers = state.drivers;
            deliveries = state.activeDeliveries;
            performance = state.performance;
          }

          final totalDrivers = (summary['total_drivers'] as num?)?.toInt() ?? 0;
          final activeDrivers = (summary['active_drivers'] as num?)?.toInt() ?? 0;
          final onlineDrivers = (summary['online_drivers'] as num?)?.toInt() ?? 0;
          final activeDeliveries = (summary['active_deliveries'] as num?)?.toInt() ?? 0;
          final todayEarnings =
              (summary['today_earnings'] as num?)?.toDouble() ?? 0.0;
          final acceptanceRate =
              (performance['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
          final completedJobs = (performance['completed_jobs'] as num?)?.toInt() ?? 0;
          final missedJobs = (performance['missed_jobs'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            color: accentColor,
            backgroundColor: isDark ? AppColors.card : AppLightColors.card,
            onRefresh: () =>
                context.read<FleetDashboardCubit>().fetchDashboard(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Time filter ─────────────────────────────────────────────
                  _FilterChips(
                    selected: _selectedFilter,
                    filters: _filters,
                    isDark: isDark,
                    onSelect: (f) => setState(() => _selectedFilter = f),
                  ),
                  SizedBox(height: 20.h),

                  // ── Summary cards ───────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.dashboard_rounded,
                      label: 'FLEET OVERVIEW',
                      isDark: isDark),
                  SizedBox(height: 12.h),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 1.6,
                    children: [
                      _MetricCard(
                          label: 'Total Drivers',
                          value: totalDrivers.toString(),
                          icon: Icons.people_rounded,
                          color: isDark ? AppColors.primaryLight : AppLightColors.primary,
                          isDark: isDark),
                      _MetricCard(
                          label: 'Active Drivers',
                          value: activeDrivers.toString(),
                          icon: Icons.how_to_reg_rounded,
                          color: AppColors.success,
                          isDark: isDark),
                      _MetricCard(
                          label: 'Online Now',
                          value: onlineDrivers.toString(),
                          icon: Icons.sensors_rounded,
                          color: accentColor,
                          isDark: isDark),
                      _MetricCard(
                          label: 'Live Deliveries',
                          value: activeDeliveries.toString(),
                          icon: Icons.local_shipping_rounded,
                          color: isDark ? AppColors.warning : AppLightColors.warning,
                          isDark: isDark),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ── Earnings ────────────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'EARNINGS',
                      isDark: isDark),
                  SizedBox(height: 12.h),
                  _EarningsBanner(
                      todayEarnings: todayEarnings,
                      selectedFilter: _selectedFilter,
                      isDark: isDark),
                  SizedBox(height: 16.h),
                  _DeliveryStatsRow(
                    completedJobs: completedJobs,
                    missedJobs: missedJobs,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),

                  // ── Performance ─────────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.bar_chart_rounded,
                      label: 'PERFORMANCE SUMMARY',
                      isDark: isDark),
                  SizedBox(height: 12.h),
                  _PerformanceSummaryCard(
                    acceptanceRate: acceptanceRate,
                    completedJobs: completedJobs,
                    missedJobs: missedJobs,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),

                  // ── Activity bar chart ──────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.bar_chart_rounded,
                      label: 'DRIVER ACTIVITY',
                      isDark: isDark),
                  SizedBox(height: 12.h),
                  _DriverBarChart(drivers: drivers, isDark: isDark),
                  SizedBox(height: 24.h),

                  // ── Driver breakdown ─────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.people_outline_rounded,
                      label: 'DRIVER BREAKDOWN',
                      isDark: isDark),
                  SizedBox(height: 12.h),
                  if (drivers.isEmpty)
                    _EmptySection(
                        label: 'No driver data available yet.', isDark: isDark)
                  else
                    ...drivers.map((d) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _DriverAnalyticsRow(
                              driver: d, isDark: isDark),
                        )),
                  SizedBox(height: 24.h),

                  // ── Active deliveries breakdown ─────────────────────────────
                  if (deliveries.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Icons.local_shipping_outlined,
                        label: 'ACTIVE DELIVERIES',
                        isDark: isDark),
                    SizedBox(height: 12.h),
                    ...deliveries.map((d) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _DeliveryRow(delivery: d, isDark: isDark),
                        )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _SectionHeader(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 14.r),
        SizedBox(width: 6.w),
        Text(label,
            style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.8)),
      ],
    );
  }
}

// ─── Metric card ──────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

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
            padding: EdgeInsets.fromLTRB(12.r, 14.r, 12.r, 12.r),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: dividerColor, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 14.r),
                ),
                const Spacer(),
                Text(value,
                    style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.1)),
                SizedBox(height: 2.h),
                Text(label,
                    style: TextStyle(
                        fontSize: 10.sp, color: textSecondary)),
              ],
            ),
          ),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 3.h, color: color)),
        ],
      ),
    );
  }
}

// ─── Earnings banner ──────────────────────────────────────────────────────────

class _EarningsBanner extends StatelessWidget {
  final double todayEarnings;
  final String selectedFilter;
  final bool isDark;
  const _EarningsBanner({
    required this.todayEarnings,
    required this.selectedFilter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$selectedFilter\'s Earnings',
                        style: TextStyle(
                            fontSize: 12.sp, color: textSecondary)),
                    SizedBox(height: 4.h),
                    Text(
                      '₹${_fmt(todayEarnings)}',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: todayEarnings > 0
                            ? AppColors.success
                            : textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.trending_up_rounded,
                    color: AppColors.success, size: 24.r),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.r, color: AppColors.success),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Earnings are updated as deliveries are completed and settled. Connect wallet for full history.',
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}K';
    return v.toStringAsFixed(2);
  }
}

// ─── Performance summary card ─────────────────────────────────────────────────

class _PerformanceSummaryCard extends StatelessWidget {
  final double acceptanceRate;
  final int completedJobs;
  final int missedJobs;
  final bool isDark;
  const _PerformanceSummaryCard({
    required this.acceptanceRate,
    required this.completedJobs,
    required this.missedJobs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final rateColor = acceptanceRate >= 80
        ? AppColors.success
        : acceptanceRate >= 50
            ? (isDark ? AppColors.warning : AppLightColors.warning)
            : (isDark ? AppColors.error : AppLightColors.error);
    final totalJobs = completedJobs + missedJobs;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acceptance Rate',
                        style: TextStyle(
                            fontSize: 12.sp, color: textSecondary)),
                    SizedBox(height: 4.h),
                    Text(
                      '${acceptanceRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: rateColor,
                          height: 1.1),
                    ),
                    Text('fleet average',
                        style: TextStyle(
                            fontSize: 11.sp, color: textSecondary)),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PerfRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      label: 'Completed',
                      value: completedJobs.toString()),
                  SizedBox(height: 8.h),
                  _PerfRow(
                      icon: Icons.cancel_rounded,
                      color: isDark ? AppColors.error : AppLightColors.error,
                      label: 'Missed',
                      value: missedJobs.toString()),
                  SizedBox(height: 8.h),
                  _PerfRow(
                      icon: Icons.format_list_numbered_rounded,
                      color: textSecondary,
                      label: 'Total',
                      value: totalJobs.toString()),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: acceptanceRate / 100,
              backgroundColor: dividerColor,
              color: rateColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _PerfRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14.r),
        SizedBox(width: 6.w),
        Text(label,
            style: TextStyle(fontSize: 11.sp, color: color)),
        SizedBox(width: 8.w),
        Text(value,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

// ─── Driver analytics row ─────────────────────────────────────────────────────

class _DriverAnalyticsRow extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool isDark;
  const _DriverAnalyticsRow({required this.driver, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;

    final name = driver['name'] as String? ?? '—';
    final status = driver['status'] as String? ?? '';
    final isOnline = driver['is_online'] == true ||
        driver['is_online'] == 1 ||
        driver['is_online'] == '1';
    final stats = driver['performance'] as Map? ?? driver['stats'] as Map? ?? {};
    final completed = (stats['completed_jobs'] as num?)?.toInt() ?? 0;
    final missed = (stats['missed_jobs'] as num?)?.toInt() ?? 0;
    final total = completed + missed;
    final rate = total > 0 ? (completed / total * 100) : 0.0;

    final statusColor = switch (status) {
      'active' => AppColors.success,
      'suspended' || 'disabled' => isDark ? AppColors.error : AppLightColors.error,
      _ => textSecondary,
    };

    return Container(
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
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp),
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
                Text(name,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: rate >= 80 ? AppColors.success : textSecondary)),
              Text('$completed/$total jobs',
                  style: TextStyle(
                      fontSize: 10.sp, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Delivery row ─────────────────────────────────────────────────────────────

class _DeliveryRow extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final bool isDark;
  const _DeliveryRow({required this.delivery, required this.isDark});

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
            'Unknown driver';
    final status = delivery['status'] as String? ?? '—';

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.local_shipping_rounded,
                color: warningColor, size: 16.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#$id',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Text(driverName,
                    style: TextStyle(
                        fontSize: 11.sp, color: textSecondary)),
              ],
            ),
          ),
          Text(
            status.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: warningColor),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  final bool isDark;
  const _EmptySection({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: textSecondary)),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final List<String> filters;
  final bool isDark;
  final ValueChanged<String> onSelect;
  const _FilterChips({
    required this.selected,
    required this.filters,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppLightColors.accent;
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Row(
      children: filters.map((f) {
        final isSelected = f == selected;
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? accent : card,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? accent : divider,
                  width: 1,
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected ? Colors.white : textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Delivery stats row ───────────────────────────────────────────────────────

class _DeliveryStatsRow extends StatelessWidget {
  final int completedJobs;
  final int missedJobs;
  final bool isDark;
  const _DeliveryStatsRow({
    required this.completedJobs,
    required this.missedJobs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = completedJobs + missedJobs;
    final error = isDark ? AppColors.error : AppLightColors.error;
    final accent = isDark ? AppColors.accent : AppLightColors.accent;

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Completed',
            value: completedJobs.toString(),
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatPill(
            label: 'Missed',
            value: missedJobs.toString(),
            color: error,
            isDark: isDark,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatPill(
            label: 'Total',
            value: total.toString(),
            color: accent,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.card : AppLightColors.card;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}

// ─── Driver activity bar chart ────────────────────────────────────────────────

class _DriverBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  final bool isDark;
  const _DriverBarChart(
      {required this.drivers, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accent = isDark ? AppColors.accent : AppLightColors.accent;

    if (drivers.isEmpty) {
      return _EmptySection(
          label: 'No driver activity data yet.', isDark: isDark);
    }

    // Build (name, completed) pairs, sort by completed desc, top 6
    final items = drivers.map((d) {
      final stats = d['performance'] as Map? ?? d['stats'] as Map? ?? {};
      final completed = (stats['completed_jobs'] as num?)?.toInt() ?? 0;
      final name = d['name'] as String? ?? '?';
      return _ChartItem(name: name, value: completed);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = items.length > 6 ? items.sublist(0, 6) : items;
    final chartMax = top.isNotEmpty && top.first.value > 0
        ? top.first.value
        : 1;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed deliveries per driver',
                style:
                    TextStyle(color: textSecondary, fontSize: 11.sp),
              ),
              Text(
                'Top ${top.length}',
                style: TextStyle(
                    color: accent,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 130.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: top.map((item) {
                final ratio = item.value / chartMax;
                final barH = (ratio * 90.h).clamp(4.h, 90.h);
                final initial = item.name.isNotEmpty
                    ? item.name[0].toUpperCase()
                    : '?';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.value > 0)
                      Text(
                        item.value.toString(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    SizedBox(height: 3.h),
                    Container(
                      width: 28.w,
                      height: barH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4.r)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent,
                            accent.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    CircleAvatar(
                      radius: 10.r,
                      backgroundColor: accent.withOpacity(0.12),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartItem {
  final String name;
  final int value;
  const _ChartItem({required this.name, required this.value});
}
