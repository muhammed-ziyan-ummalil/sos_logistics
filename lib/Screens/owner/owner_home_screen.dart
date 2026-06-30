import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Bloc/Fleet/fleet_dashboard_cubit.dart';
import '../../Bloc/Fleet/fleet_dashboard_state.dart';
import '../../Bloc/OwnerProfile/owner_profile_cubit.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../utility/api_service.dart';
import '../../utility/shared_preference.dart';
import '../../widgets/widgets.dart';
import '../notifications/notification_bell.dart';
import 'account/owner_edit_profile_screen.dart';
import 'delivery/delivery_feed_screen.dart';
import 'delivery/my_quotes_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  String _ownerName = '';
  bool _serviceAreaMissing = false;

  @override
  void initState() {
    super.initState();
    context.read<FleetDashboardCubit>().fetchDashboard();
    _loadName();
    _checkServiceArea();
  }

  Future<void> _loadName() async {
    final info = await AppPrefs.getV2Session();
    if (mounted) setState(() => _ownerName = info['name'] ?? '');
  }

  Future<void> _checkServiceArea() async {
    final res = await ApiServiceV2.instance.get('owner/me');
    if (!mounted) return;
    if (res['status'] == 'success') {
      final owner = (res['data']?['owner'] as Map?) ?? {};
      setState(() {
        _serviceAreaMissing =
            owner['service_lat'] == null || owner['service_lng'] == null;
      });
    }
  }

  Future<void> _openServiceAreaSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OwnerProfileCubit(),
          child: const OwnerEditProfileScreen(),
        ),
      ),
    );
    await _checkServiceArea(); // banner clears once area is saved
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: SosAppBar(
        title: _ownerName.isNotEmpty
            ? '${_greeting()}, $_ownerName'
            : _greeting(),
        actions: [
          const NotificationBell(role: 'owner'),
          BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
            builder: (_, s) => IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: AppTheme.textSecondary(context), size: 20.r),
              onPressed: s is FleetDashboardLoading
                  ? null
                  : () =>
                      context.read<FleetDashboardCubit>().fetchDashboard(),
            ),
          ),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────
      body: Column(
        children: [
          if (_serviceAreaMissing)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: _ServiceAreaBanner(onTap: _openServiceAreaSetup),
            ),
          Expanded(
            child: BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
              builder: (ctx, state) {
                if (state is FleetDashboardInitial ||
                    state is FleetDashboardLoading) {
                  return _LoadingPlaceholder();
                }
                if (state is FleetDashboardError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<FleetDashboardCubit>().fetchDashboard(),
                  );
                }
                if (state is FleetDashboardLoaded) {
                  return _HomeBody(state: state);
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

// ─── Loading placeholder ──────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // Stats row skeleton
          SizedBox(
            height: 110.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: SkeletonBox(width: 112.w, height: 110.h, radius: 14),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          SkeletonBox(width: 120.w, height: 14.h),
          SizedBox(height: 12.h),
          SkeletonBox(height: 70.h),
          SizedBox(height: 8.h),
          SkeletonBox(height: 70.h),
          SizedBox(height: 24.h),
          SkeletonBox(width: 120.w, height: 14.h),
          SizedBox(height: 12.h),
          SkeletonBox(height: 90.h),
          SizedBox(height: 24.h),
          SkeletonBox(width: 140.w, height: 14.h),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 80.h)),
              SizedBox(width: 10.w),
              Expanded(child: SkeletonBox(height: 80.h)),
              SizedBox(width: 10.w),
              Expanded(child: SkeletonBox(height: 80.h)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Home body ────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final FleetDashboardLoaded state;
  const _HomeBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.accent(context),
      backgroundColor: AppTheme.card(context),
      onRefresh: () => context.read<FleetDashboardCubit>().fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // Stats cards
            _StatsRow(summary: state.summary),
            SizedBox(height: 20.h),

            // Driver snapshot
            if (state.drivers.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _DriverSnapshotSection(drivers: state.drivers),
              ),
            if (state.drivers.isNotEmpty) SizedBox(height: 20.h),

            // Active deliveries — always show (empty state if none)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _ActiveDeliveriesSection(
                  deliveries: state.activeDeliveries),
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
                ),
              ),
              SizedBox(height: 20.h),
            ],

            // Performance
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _PerformanceSection(performance: state.performance),
            ),
            SizedBox(height: 20.h),

            // Quick links to Manage
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: const _ManageShortcuts(),
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
  const _StatsRow({required this.summary});

  String _fmtNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final totalDrivers = summary['total_drivers']?.toString() ?? '0';
    final activeDrivers = summary['active_drivers']?.toString() ?? '0';
    final activeDeliveries = summary['active_deliveries']?.toString() ?? '0';
    final earnings = summary['today_earnings'];
    final earningsStr = earnings != null
        ? '${AppConstants.currencySymbol}${_fmtNum(double.tryParse(earnings.toString()) ?? 0)}'
        : '${AppConstants.currencySymbol}0';

    final cards = [
      _StatData(
          icon: Icons.people_rounded,
          label: 'Total\nDrivers',
          value: totalDrivers,
          color: Theme.of(context).colorScheme.primary),
      _StatData(
          icon: Icons.check_circle_rounded,
          label: 'Active\nDrivers',
          value: activeDrivers,
          color: AppDesignTokens.success),
      _StatData(
          icon: Icons.local_shipping_rounded,
          label: 'Live\nDeliveries',
          value: activeDeliveries,
          color: AppDesignTokens.warning),
      _StatData(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Today\'s\nEarnings',
          value: earningsStr,
          color: AppDesignTokens.success),
    ];

    return SizedBox(
      height: 110.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: cards.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: 10.w),
          child: _StatCard(data: cards[i]),
        ),
      ),
    );
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
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Stack(
        children: [
          Container(
            width: 112.w,
            padding: EdgeInsets.fromLTRB(12.r, 16.r, 12.r, 12.r),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: scheme.outline, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Icon(data.icon, color: data.color, size: 14.r),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.value,
                        style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    SizedBox(height: 2.h),
                    Text(data.label,
                        style: TextStyle(
                            color: AppTheme.textSecondary(context),
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
  const _ActiveDeliveriesSection({required this.deliveries});

  @override
  Widget build(BuildContext context) {
    final warningColor = AppDesignTokens.warning;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.local_shipping_rounded,
            label: 'ACTIVE DELIVERIES',
            color: warningColor),
        SizedBox(height: 10.h),
        if (deliveries.isEmpty)
          SosCard(
            padding: EdgeInsets.all(20.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded,
                    color: scheme.outline, size: 20.r),
                SizedBox(width: 10.w),
                Text('No active deliveries right now',
                    style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 13.sp)),
              ],
            ),
          )
        else
          ...deliveries.map((d) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _DeliveryTile(delivery: d),
              )),
      ],
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final Map<String, dynamic> delivery;
  const _DeliveryTile({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final warningColor = AppDesignTokens.warning;

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

    return SosCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.12),
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
                        color: AppTheme.textPrimary(context),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(driverName,
                    style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11.sp)),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: status),
                if (eta != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 10.r,
                          color: AppTheme.textSecondary(context)),
                      SizedBox(width: 3.w),
                      Text(eta,
                          style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 10.sp)),
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
  const _AlertsSection(
      {required this.inactive, required this.unassigned});

  @override
  Widget build(BuildContext context) {
    final warningColor = AppDesignTokens.warning;
    final errorColor = AppTheme.error(context);

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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
  const _PerformanceSection({required this.performance});

  @override
  Widget build(BuildContext context) {
    final acceptanceRate =
        (performance['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
    final missedJobs = (performance['missed_jobs'] as num?)?.toInt() ?? 0;
    final completedJobs =
        (performance['completed_jobs'] as num?)?.toInt() ?? 0;
    final accentColor = AppTheme.accent(context);
    final errorColor = AppTheme.error(context);
    final rateColor = acceptanceRate >= 80
        ? AppDesignTokens.success
        : acceptanceRate >= 50
            ? AppDesignTokens.warning
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
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _PerfCard(
                label: 'Missed Jobs',
                value: missedJobs.toString(),
                icon: Icons.cancel_rounded,
                color: missedJobs == 0 ? AppDesignTokens.success : errorColor,
                subLabel: 'this month',
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _PerfCard(
                label: 'Completed',
                value: completedJobs.toString(),
                icon: Icons.check_circle_rounded,
                color: AppDesignTokens.success,
                subLabel: 'this month',
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
  const _PerfCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SosCard(
      padding: EdgeInsets.all(13.r),
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
                  color: scheme.onSurface,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500)),
          Text(subLabel,
              style: TextStyle(
                  color: AppTheme.textSecondary(context), fontSize: 9.sp)),
        ],
      ),
    );
  }
}

// ─── Manage shortcuts ─────────────────────────────────────────────────────────

class _ManageShortcuts extends StatelessWidget {
  const _ManageShortcuts();

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);
    final successColor = AppDesignTokens.success;

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
                child: _QuickActionCard(
                  icon: Icons.person_add_rounded,
                  label: 'Add Driver',
                  color: accentColor,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.v2VehicleList),
                child: _QuickActionCard(
                  icon: Icons.directions_car_rounded,
                  label: 'Add Vehicle',
                  color: accentColor,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.v2DriverList),
                child: _QuickActionCard(
                  icon: Icons.list_rounded,
                  label: 'All Drivers',
                  color: accentColor,
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
                  MaterialPageRoute(
                      builder: (_) => const DeliveryFeedScreen()),
                ),
                child: _QuickActionCard(
                  icon: Icons.local_shipping,
                  label: 'Available Deliveries',
                  color: successColor,
                  textAlign: TextAlign.center,
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
                child: _QuickActionCard(
                  icon: Icons.receipt_long,
                  label: 'My Quotes',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final TextAlign textAlign;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22.r),
          SizedBox(height: 6.h),
          Text(label,
              textAlign: textAlign,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
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
  const _StatusBadge({required this.status});

  SosTone _tone(String s) => switch (s) {
        'active' || 'completed' || 'delivered' => SosTone.success,
        'suspended' || 'disabled' || 'rejected' || 'failed' => SosTone.error,
        'in_progress' || 'picked_up' => SosTone.warning,
        _ => SosTone.neutral,
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
    return SosChip(label: _label(status), tone: _tone(status));
  }
}

// ─── Driver snapshot ──────────────────────────────────────────────────────────

class _DriverSnapshotSection extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  const _DriverSnapshotSection({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);
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
              child: _DriverSnapshotTile(driver: d),
            )),
      ],
    );
  }
}

class _DriverSnapshotTile extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverSnapshotTile({required this.driver});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = scheme.primary;

    final name = driver['name'] as String? ?? '—';
    final status = driver['status'] as String? ?? '';
    final isOnline = driver['is_online'] == true ||
        driver['is_online'] == 1 ||
        driver['is_online'] == '1';
    final vehicle = driver['vehicle'] as Map<String, dynamic>?;
    final plate = vehicle?['reg_number'] as String? ?? 'No vehicle';
    final vehicleType = vehicle?['type'] as String?;

    final statusColor = switch (status) {
      'active' => AppDesignTokens.success,
      'suspended' || 'disabled' => AppTheme.error(context),
      _ => AppTheme.textSecondary(context),
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
      child: SosCard(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
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
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
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
                          size: 10.r,
                          color: AppTheme.textSecondary(context)),
                      SizedBox(width: 3.w),
                      Flexible(
                        child: Text(
                          plate,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondary(context),
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
                      style: TextStyle(
                          fontSize: 9.sp,
                          color: AppTheme.textSecondary(context)),
                    ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 16.r),
          ],
        ),
      ),
    );
  }
}

// ─── Service area banner ──────────────────────────────────────────────────────

class _ServiceAreaBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ServiceAreaBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final warningColor = AppDesignTokens.warning;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: warningColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: warningColor.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wrong_location_rounded,
                  color: warningColor, size: 20.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your service area',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "You won't receive delivery requests until you set where you operate.",
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: AppTheme.textSecondary(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: warningColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Set up',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
