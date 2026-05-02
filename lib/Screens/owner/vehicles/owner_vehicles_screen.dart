import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import '../../../Bloc/OwnerVehicles/owner_vehicles_state.dart';
import '../../../core/app_theme.dart';

class OwnerVehiclesScreen extends StatefulWidget {
  const OwnerVehiclesScreen({super.key});

  @override
  State<OwnerVehiclesScreen> createState() => _OwnerVehiclesScreenState();
}

class _OwnerVehiclesScreenState extends State<OwnerVehiclesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OwnerVehiclesCubit>().fetchVehicles();
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
        title: Text('Vehicles',
            style: TextStyle(color: textPrimary, fontSize: 17.sp)),
        centerTitle: true,
        actions: [
          BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
            builder: (_, s) => IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                  size: 20.r),
              onPressed: s is OwnerVehiclesLoading
                  ? null
                  : () => context.read<OwnerVehiclesCubit>().fetchVehicles(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleSheet(context, isDark),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_rounded, size: 18.r),
        label: Text('Add Vehicle',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      ),
      body: BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
        builder: (ctx, state) {
          if (state is OwnerVehiclesInitial || state is OwnerVehiclesLoading) {
            return Center(
                child: CircularProgressIndicator(
                    color: accentColor, strokeWidth: 2.5));
          }
          if (state is OwnerVehiclesError) {
            return _ErrorWidget(
              message: state.message,
              isDark: isDark,
              onRetry: () => context.read<OwnerVehiclesCubit>().fetchVehicles(),
            );
          }
          if (state is OwnerVehiclesLoaded) {
            if (state.vehicles.isEmpty) {
              return _EmptyState(isDark: isDark,
                  onAdd: () => _showAddVehicleSheet(context, isDark));
            }
            return RefreshIndicator(
              color: accentColor,
              backgroundColor: isDark ? AppColors.card : AppLightColors.card,
              onRefresh: () => context.read<OwnerVehiclesCubit>().fetchVehicles(),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
                itemCount: state.vehicles.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _VehicleTile(vehicle: state.vehicles[i], isDark: isDark),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAddVehicleSheet(BuildContext context, bool isDark) {
    final regCtr = TextEditingController();
    String selectedType = 'truck';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
          final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
          final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
          final textSecondary =
              isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
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
                  Text('Add Vehicle',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  Text('Register a new vehicle to your fleet',
                      style: TextStyle(fontSize: 12.sp, color: textSecondary)),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: regCtr,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: textPrimary, fontSize: 14.sp),
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      prefixIcon: Icon(Icons.pin_rounded),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text('Vehicle Type',
                      style: TextStyle(fontSize: 12.sp, color: textSecondary)),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: ['truck', 'van', 'bike', 'pickup'].map((t) {
                      final sel = selectedType == t;
                      final primary =
                          isDark ? AppColors.primaryLight : AppLightColors.primary;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedType = t),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: sel ? primary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                                color: sel ? primary : dividerColor),
                          ),
                          child: Text(t.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                color: sel ? primary : textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final reg = regCtr.text.trim();
                        if (reg.isEmpty) return;
                        Navigator.pop(sheetCtx);
                        context.read<OwnerVehiclesCubit>().addVehicle(
                            regNumber: reg, type: selectedType);
                      },
                      child: const Text('Add Vehicle'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Vehicle tile ─────────────────────────────────────────────────────────────

class _VehicleTile extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isDark;
  const _VehicleTile({required this.vehicle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final warningColor = isDark ? AppColors.warning : AppLightColors.warning;

    final regNum = vehicle['reg_number'] as String? ?? '—';
    final type = (vehicle['type'] as String? ?? 'vehicle').toUpperCase();
    final assignedDriver = vehicle['assigned_driver'] as Map<String, dynamic>?;
    final driverName = assignedDriver?['name'] as String? ?? 'Unassigned';
    final isAssigned = assignedDriver != null;
    final capacityKg = vehicle['capacity_kg'];
    final insuranceExpiry = vehicle['insurance_expiry'] as String?;

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
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.directions_car_rounded,
                color: warningColor, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regNum,
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                SizedBox(height: 2.h),
                Text(type,
                    style: TextStyle(fontSize: 11.sp, color: textSecondary)),
                if (capacityKg != null) ...[
                  SizedBox(height: 2.h),
                  Text('Capacity: ${capacityKg}kg',
                      style: TextStyle(fontSize: 11.sp, color: textSecondary)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AssignedBadge(isAssigned: isAssigned, name: driverName, isDark: isDark),
              if (insuranceExpiry != null) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 10.r, color: textSecondary),
                    SizedBox(width: 3.w),
                    Text(insuranceExpiry,
                        style: TextStyle(fontSize: 9.sp, color: textSecondary)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  final bool isAssigned;
  final String name;
  final bool isDark;
  const _AssignedBadge(
      {required this.isAssigned, required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isAssigned
        ? AppColors.success
        : (isDark ? AppColors.textSecondary : AppLightColors.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            isAssigned ? 'ASSIGNED' : 'AVAILABLE',
            style: TextStyle(
                fontSize: 9.sp, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        SizedBox(height: 3.h),
        Text(name,
            style: TextStyle(
                fontSize: 10.sp,
                color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
      ],
    );
  }
}

// ─── Empty + Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  const _EmptyState({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 48.r, color: divider),
            SizedBox(height: 16.h),
            Text('No vehicles yet',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            SizedBox(height: 6.h),
            Text('Add your first vehicle to start assigning to drivers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: textSecondary)),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_rounded, size: 16.r),
              label: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorWidget(
      {required this.message, required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: isDark ? AppColors.error : AppLightColors.error, size: 36.r),
            SizedBox(height: 12.h),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                    fontSize: 13.sp)),
            SizedBox(height: 16.h),
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
