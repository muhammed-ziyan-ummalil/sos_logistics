import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/Fleet/fleet_dashboard_cubit.dart';
import '../../../Bloc/Fleet/fleet_dashboard_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

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
    // Ancestor-provided cubit — do NOT add a BlocProvider here.
    final s = context.read<FleetDashboardCubit>().state;
    if (s is FleetDashboardInitial) {
      context.read<FleetDashboardCubit>().fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const SosAppBar(title: 'Reporting & Analytics'),
      body: BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
        builder: (ctx, state) {
          if (state is FleetDashboardInitial || state is FleetDashboardLoading) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 44.h),
                  SizedBox(height: 20.h),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 1.6,
                    children: List.generate(4,
                        (_) => SkeletonBox(width: double.infinity, height: 80.h,
                            radius: AppDesignTokens.radiusCard)),
                  ),
                  SizedBox(height: 20.h),
                  SkeletonBox(width: double.infinity, height: 110.h,
                      radius: AppDesignTokens.radiusCard),
                  SizedBox(height: 20.h),
                  ...List.generate(3,
                      (_) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: SkeletonBox(
                                width: double.infinity, height: 60.h,
                                radius: AppDesignTokens.radiusCard),
                          )),
                ],
              ),
            );
          }

          if (state is FleetDashboardError) {
            return ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<FleetDashboardCubit>().fetchDashboard(),
            );
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

          final totalDrivers =
              (summary['total_drivers'] as num?)?.toInt() ?? 0;
          final activeDrivers =
              (summary['active_drivers'] as num?)?.toInt() ?? 0;
          final onlineDrivers =
              (summary['online_drivers'] as num?)?.toInt() ?? 0;
          final activeDeliveries =
              (summary['active_deliveries'] as num?)?.toInt() ?? 0;
          final todayEarnings =
              (summary['today_earnings'] as num?)?.toDouble() ?? 0.0;
          final acceptanceRate =
              (performance['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
          final completedJobs =
              (performance['completed_jobs'] as num?)?.toInt() ?? 0;
          final missedJobs =
              (performance['missed_jobs'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            color: scheme.primary,
            backgroundColor: scheme.surface,
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
                    onSelect: (f) => setState(() => _selectedFilter = f),
                  ),
                  SizedBox(height: 20.h),

                  // ── Summary cards — StatTile grid ───────────────────────────
                  _SectionHeader(
                      icon: Icons.dashboard_rounded,
                      label: 'FLEET OVERVIEW'),
                  SizedBox(height: 12.h),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 1.6,
                    children: [
                      StatTile(
                          label: 'Total Drivers',
                          value: totalDrivers.toString(),
                          icon: Icons.people_rounded),
                      StatTile(
                          label: 'Active Drivers',
                          value: activeDrivers.toString(),
                          icon: Icons.how_to_reg_rounded),
                      StatTile(
                          label: 'Online Now',
                          value: onlineDrivers.toString(),
                          icon: Icons.sensors_rounded),
                      StatTile(
                          label: 'Live Deliveries',
                          value: activeDeliveries.toString(),
                          icon: Icons.local_shipping_rounded),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ── Earnings ────────────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'EARNINGS'),
                  SizedBox(height: 12.h),
                  _EarningsBanner(
                      todayEarnings: todayEarnings,
                      selectedFilter: _selectedFilter),
                  SizedBox(height: 16.h),
                  _DeliveryStatsRow(
                    completedJobs: completedJobs,
                    missedJobs: missedJobs,
                  ),
                  SizedBox(height: 24.h),

                  // ── Performance ─────────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.bar_chart_rounded,
                      label: 'PERFORMANCE SUMMARY'),
                  SizedBox(height: 12.h),
                  _PerformanceSummaryCard(
                    acceptanceRate: acceptanceRate,
                    completedJobs: completedJobs,
                    missedJobs: missedJobs,
                  ),
                  SizedBox(height: 24.h),

                  // ── Activity bar chart ──────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.bar_chart_rounded, label: 'DRIVER ACTIVITY'),
                  SizedBox(height: 12.h),
                  // Keep the pure-Flutter proportional-bar widget — just restyle colors.
                  _DriverBarChart(drivers: drivers),
                  SizedBox(height: 24.h),

                  // ── Driver breakdown ─────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.people_outline_rounded,
                      label: 'DRIVER BREAKDOWN'),
                  SizedBox(height: 12.h),
                  if (drivers.isEmpty)
                    SosCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Text('No driver data available yet.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ),
                    )
                  else
                    ...drivers.map((d) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _DriverAnalyticsRow(driver: d),
                        )),
                  SizedBox(height: 24.h),

                  // ── Active deliveries breakdown ─────────────────────────────
                  if (deliveries.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Icons.local_shipping_outlined,
                        label: 'ACTIVE DELIVERIES'),
                    SizedBox(height: 12.h),
                    ...deliveries.map((d) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _DeliveryRow(delivery: d),
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
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, color: color, size: 14.r),
        SizedBox(width: 6.w),
        Text(label,
            style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8)),
      ],
    );
  }
}

// ─── Earnings banner ──────────────────────────────────────────────────────────

class _EarningsBanner extends StatelessWidget {
  final double todayEarnings;
  final String selectedFilter;

  const _EarningsBanner({
    required this.todayEarnings,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$selectedFilter's Earnings",
                        style: theme.textTheme.bodySmall),
                    SizedBox(height: 4.h),
                    Text(
                      '${AppConstants.currencySymbol}${_fmt(todayEarnings)}',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: todayEarnings > 0
                            ? AppDesignTokens.success
                            : theme.colorScheme.onSurface,
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
                  color: AppDesignTokens.success.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusS),
                ),
                child: Icon(Icons.trending_up_rounded,
                    color: AppDesignTokens.success, size: 24.r),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppDesignTokens.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusXS),
              border: Border.all(
                  color: AppDesignTokens.success.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14.r, color: AppDesignTokens.success),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Earnings are updated as deliveries are completed and settled. Connect wallet for full history.',
                    style: TextStyle(
                        fontSize: 11.sp, color: AppDesignTokens.success),
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

  const _PerformanceSummaryCard({
    required this.acceptanceRate,
    required this.completedJobs,
    required this.missedJobs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rateColor = acceptanceRate >= 80
        ? AppDesignTokens.success
        : acceptanceRate >= 50
            ? AppDesignTokens.warning
            : scheme.error;
    final totalJobs = completedJobs + missedJobs;

    return SosCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acceptance Rate',
                        style: Theme.of(context).textTheme.bodySmall),
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
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PerfRow(
                      icon: Icons.check_circle_rounded,
                      color: AppDesignTokens.success,
                      label: 'Completed',
                      value: completedJobs.toString()),
                  SizedBox(height: 8.h),
                  _PerfRow(
                      icon: Icons.cancel_rounded,
                      color: scheme.error,
                      label: 'Missed',
                      value: missedJobs.toString()),
                  SizedBox(height: 8.h),
                  _PerfRow(
                      icon: Icons.format_list_numbered_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
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
              backgroundColor: scheme.outline,
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
        Text(label, style: TextStyle(fontSize: 11.sp, color: color)),
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

// ─── Driver analytics row — SosCard-wrapped ───────────────────────────────────

class _DriverAnalyticsRow extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverAnalyticsRow({required this.driver});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final name = driver['name'] as String? ?? '—';
    final status = driver['status'] as String? ?? '';
    final isOnline = driver['is_online'] == true ||
        driver['is_online'] == 1 ||
        driver['is_online'] == '1';
    final stats =
        driver['performance'] as Map? ?? driver['stats'] as Map? ?? {};
    final completed = (stats['completed_jobs'] as num?)?.toInt() ?? 0;
    final missed = (stats['missed_jobs'] as num?)?.toInt() ?? 0;
    final total = completed + missed;
    final rate = total > 0 ? (completed / total * 100) : 0.0;

    return SosCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: scheme.primary,
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
                    color: isOnline
                        ? AppDesignTokens.success
                        : scheme.outline,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: scheme.surface, width: 1.5),
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 13.sp)),
                Row(
                  children: [
                    // Status badge via SosChip
                    SosChip(
                      label: status.toUpperCase().replaceAll('_', ' '),
                      tone: switch (status) {
                        'active' => SosTone.success,
                        'suspended' || 'disabled' => SosTone.error,
                        _ => SosTone.neutral,
                      },
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
                      color: rate >= 80
                          ? AppDesignTokens.success
                          : scheme.onSurface)),
              Text('$completed/$total jobs',
                  style: Theme.of(context).textTheme.bodySmall),
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
  const _DeliveryRow({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final id = delivery['delivery_id']?.toString() ??
        delivery['id']?.toString() ??
        '—';
    final driverName =
        (delivery['driver'] as Map?)?['name'] as String? ??
            delivery['driver_name'] as String? ??
            'Unknown driver';
    final status = delivery['status'] as String? ?? '—';

    return SosCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: AppDesignTokens.warning.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusXS),
            ),
            child: Icon(Icons.local_shipping_rounded,
                color: AppDesignTokens.warning, size: 16.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#$id',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 13.sp)),
                Text(driverName,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          SosChip(
            label: status.toUpperCase().replaceAll('_', ' '),
            tone: SosTone.warning,
          ),
        ],
      ),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final List<String> filters;
  final ValueChanged<String> onSelect;

  const _FilterChips({
    required this.selected,
    required this.filters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: filters.map((f) {
        final isSelected = f == selected;
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outline,
                  width: 1,
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.65),
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

  const _DeliveryStatsRow({
    required this.completedJobs,
    required this.missedJobs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = completedJobs + missedJobs;

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Completed',
            value: completedJobs.toString(),
            color: AppDesignTokens.success,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatPill(
            label: 'Missed',
            value: missedJobs.toString(),
            color: scheme.error,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatPill(
            label: 'Total',
            value: total.toString(),
            color: scheme.primary,
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

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SosCard(
      padding: EdgeInsets.symmetric(vertical: 12.h),
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
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Driver activity bar chart — pure-Flutter proportional bars (KEPT) ────────
// Bars restyled to colorScheme.primary / AppDesignTokens.success.

class _DriverBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  const _DriverBarChart({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (drivers.isEmpty) {
      return SosCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Text('No driver activity data yet.',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      );
    }

    // Build (name, completed) pairs, sort by completed desc, top 6.
    final items = drivers.map((d) {
      final stats =
          d['performance'] as Map? ?? d['stats'] as Map? ?? {};
      final completed = (stats['completed_jobs'] as num?)?.toInt() ?? 0;
      final name = d['name'] as String? ?? '?';
      return _ChartItem(name: name, value: completed);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = items.length > 6 ? items.sublist(0, 6) : items;
    final chartMax =
        top.isNotEmpty && top.first.value > 0 ? top.first.value : 1;

    return SosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed deliveries per driver',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Top ${top.length}',
                style: TextStyle(
                    color: scheme.primary,
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
                          color: scheme.primary,
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
                            scheme.primary,
                            AppDesignTokens.success
                                .withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    CircleAvatar(
                      radius: 10.r,
                      backgroundColor:
                          scheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: scheme.primary,
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
