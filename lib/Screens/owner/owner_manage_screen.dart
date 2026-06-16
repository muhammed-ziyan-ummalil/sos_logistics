import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Bloc/Fleet/fleet_dashboard_cubit.dart';
import '../../Bloc/Fleet/fleet_dashboard_state.dart';
import '../../Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import '../../Bloc/OwnerVehicles/owner_vehicles_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';

class OwnerManageScreen extends StatefulWidget {
  const OwnerManageScreen({super.key});

  @override
  State<OwnerManageScreen> createState() => _OwnerManageScreenState();
}

class _OwnerManageScreenState extends State<OwnerManageScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh vehicles count whenever Manage tab is opened
    context.read<OwnerVehiclesCubit>().fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Header
          Container(
            color: surfaceColor,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.grid_view_rounded, color: accentColor, size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      'Manage',
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
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                children: [
                  _DriversManageCard(isDark: isDark),
                  SizedBox(height: 16.h),
                  _VehiclesManageCard(isDark: isDark),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drivers Manage Card ──────────────────────────────────────────────────────

class _DriversManageCard extends StatelessWidget {
  final bool isDark;
  const _DriversManageCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.people_rounded, color: primary, size: 18.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Drivers',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                      Text('Manage your driver fleet',
                          style: TextStyle(
                              fontSize: 12.sp, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats from FleetDashboardCubit
          BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
            builder: (_, state) {
              int total = 0, active = 0, online = 0;
              if (state is FleetDashboardLoaded) {
                total = state.drivers.length;
                active = state.drivers.where((d) => d['status'] == 'active').length;
                online = state.drivers.where((d) {
                  final v = d['is_online'];
                  return v == true || v == 1 || v == '1';
                }).length;
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _MiniStat(
                        label: 'Total', value: total.toString(), isDark: isDark),
                    _Divider(isDark: isDark),
                    _MiniStat(
                        label: 'Active',
                        value: active.toString(),
                        isDark: isDark,
                        color: AppColors.success),
                    _Divider(isDark: isDark),
                    _MiniStat(
                        label: 'Online',
                        value: online.toString(),
                        isDark: isDark,
                        color: isDark ? AppColors.accent : AppLightColors.accent),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 14.h),

          Divider(color: dividerColor, height: 1),
          SizedBox(height: 12.h),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.list_rounded,
                    label: 'All Drivers',
                    isPrimary: true,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.v2DriverList),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Add Driver',
                    isPrimary: false,
                    isDark: isDark,
                    onTap: () async {
                      final added = await Navigator.pushNamed(
                          context, AppRoutes.v2AddDriver);
                      if (added == true && context.mounted) {
                        context.read<FleetDashboardCubit>().fetchDashboard();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicles Manage Card ─────────────────────────────────────────────────────

class _VehiclesManageCard extends StatelessWidget {
  final bool isDark;
  const _VehiclesManageCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final warningColor = isDark ? AppColors.warning : AppLightColors.warning;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: warningColor, size: 18.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicles',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                      Text('Track and assign your vehicles',
                          style: TextStyle(
                              fontSize: 12.sp, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats from OwnerVehiclesCubit
          BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
            builder: (_, state) {
              int total = 0, assigned = 0, available = 0;
              if (state is OwnerVehiclesLoaded) {
                total = state.vehicles.length;
                assigned = state.vehicles
                    .where((v) =>
                        v['assigned_driver'] != null ||
                        v['assigned_driver_id'] != null)
                    .length;
                available = total - assigned;
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _MiniStat(
                        label: 'Total', value: total.toString(), isDark: isDark),
                    _Divider(isDark: isDark),
                    _MiniStat(
                        label: 'Assigned',
                        value: assigned.toString(),
                        isDark: isDark,
                        color: isDark ? AppColors.accent : AppLightColors.accent),
                    _Divider(isDark: isDark),
                    _MiniStat(
                        label: 'Available',
                        value: available.toString(),
                        isDark: isDark,
                        color: AppColors.success),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 14.h),

          Divider(color: dividerColor, height: 1),
          SizedBox(height: 12.h),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.list_rounded,
                    label: 'All Vehicles',
                    isPrimary: true,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.v2VehicleList),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_rounded,
                    label: 'Add Vehicle',
                    isPrimary: false,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.v2VehicleList,
                      arguments: {'openAdd': true},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: color ?? textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(fontSize: 11.sp, color: textSecondary)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32.h,
      color: isDark ? AppColors.divider : AppLightColors.divider,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final primaryColor = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final color = isPrimary ? primaryColor : accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(isPrimary ? 0 : 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.r,
                color: isPrimary ? Colors.white : color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
