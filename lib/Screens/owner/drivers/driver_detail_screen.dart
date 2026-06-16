import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/Fleet/driver_detail_cubit.dart';
import '../../../Bloc/Fleet/driver_detail_state.dart';
import '../../../Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import '../../../Bloc/OwnerVehicles/owner_vehicles_state.dart';
import '../../../core/app_theme.dart';

class DriverDetailScreen extends StatefulWidget {
  final String driverId;
  final Map<String, dynamic> initialDriver;

  const DriverDetailScreen({
    required this.driverId,
    required this.initialDriver,
    super.key,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DriverDetailCubit>().fetchDriver(widget.driverId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surface = isDark ? AppColors.surface : AppLightColors.surface;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;

    return BlocConsumer<DriverDetailCubit, DriverDetailState>(
      listener: (ctx, state) {
        if (state is DriverDetailActionSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.success,
          ));
        } else if (state is DriverDetailActionError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: isDark ? AppColors.error : AppLightColors.error,
          ));
        }
      },
      builder: (ctx, state) {
        final driver = _resolveDriver(state) ?? widget.initialDriver;
        final isActionLoading = state is DriverDetailActionLoading;
        final isFullLoading =
            state is DriverDetailLoading || state is DriverDetailInitial;

        if (isFullLoading) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: surface,
              leading: BackButton(color: textSecondary),
              title: const Text('Driver Detail'),
            ),
            body: Center(
              child: CircularProgressIndicator(
                  color: accentColor, strokeWidth: 2.5),
            ),
          );
        }

        if (state is DriverDetailError && _resolveDriver(state) == null) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: surface,
              leading: BackButton(color: textSecondary),
              title: const Text('Driver Detail'),
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color:
                            isDark ? AppColors.error : AppLightColors.error,
                        size: 40.r),
                    SizedBox(height: 12.h),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textSecondary, fontSize: 13.sp)),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DriverDetailCubit>()
                          .fetchDriver(widget.driverId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final name = driver['name'] as String? ?? '—';
        final status = driver['status'] as String? ?? '';
        final isActive = status == 'active';
        final isSuspended = status == 'suspended' || status == 'disabled';

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: surface,
            leading: BackButton(color: textSecondary),
            title: Text(name),
            actions: [
              if (isActionLoading)
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accentColor),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DriverInfoCard(driver: driver),
                SizedBox(height: 16.h),
                _VehicleCard(
                  driver: driver,
                  driverId: widget.driverId,
                  isActionLoading: isActionLoading,
                ),
                SizedBox(height: 16.h),
                _SectionLabel(label: 'ACCOUNT STATUS'),
                SizedBox(height: 10.h),
                _StatusControlCard(
                  currentStatus: status,
                  isActive: isActive,
                  isSuspended: isSuspended,
                  isLoading: isActionLoading,
                  onActivate: () => _confirmStatusChange(
                    ctx: context,
                    title: 'Activate Driver',
                    message:
                        'This will allow $name to go online and receive deliveries.',
                    confirmLabel: 'Activate',
                    confirmColor: AppColors.success,
                    onConfirm: () => context
                        .read<DriverDetailCubit>()
                        .setStatus(widget.driverId, 'active'),
                  ),
                  onSuspend: () => _confirmStatusChange(
                    ctx: context,
                    title: 'Suspend Driver',
                    message:
                        '$name will be taken offline and cannot receive any deliveries.',
                    confirmLabel: 'Suspend',
                    confirmColor:
                        isDark ? AppColors.error : AppLightColors.error,
                    onConfirm: () => context
                        .read<DriverDetailCubit>()
                        .setStatus(widget.driverId, 'suspended'),
                  ),
                ),
                SizedBox(height: 16.h),
                _SectionLabel(label: 'PERFORMANCE'),
                SizedBox(height: 10.h),
                _PerformanceRow(driver: driver),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic>? _resolveDriver(DriverDetailState state) {
    if (state is DriverDetailLoaded) return state.driver;
    if (state is DriverDetailActionLoading) return state.driver;
    if (state is DriverDetailActionSuccess) return state.driver;
    if (state is DriverDetailActionError) return state.driver;
    return null;
  }

  Future<void> _confirmStatusChange({
    required BuildContext ctx,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surface : AppLightColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimary
                : AppLightColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondary
                : AppLightColors.textSecondary,
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                  color: confirmColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }
}

// ─── Driver info card ─────────────────────────────────────────────────────────

class _DriverInfoCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverInfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;

    final name = driver['name'] as String? ?? '—';
    final phone = driver['phone'] as String? ?? '—';
    final email = driver['email'] as String? ?? '—';
    final status = driver['status'] as String? ?? '';
    final isOnline = driver['is_online'] == true ||
        driver['is_online'] == 1 ||
        driver['is_online'] == '1';
    final license = driver['license_number'] as String?;
    final licenseExpiry = driver['license_expiry'] as String?;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: primary.withOpacity(0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13.r,
                      height: 13.r,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.success : divider,
                        shape: BoxShape.circle,
                        border: Border.all(color: card, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _StatusBadge(status: status),
                        SizedBox(width: 6.w),
                        _OnlineBadge(isOnline: isOnline),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: divider, height: 1),
          SizedBox(height: 14.h),
          _InfoRow(
              icon: Icons.phone_outlined, label: 'Phone', value: phone),
          SizedBox(height: 10.h),
          _InfoRow(
              icon: Icons.email_outlined, label: 'Email', value: email),
          if (license != null) ...[
            SizedBox(height: 10.h),
            _InfoRow(
                icon: Icons.badge_outlined,
                label: 'License',
                value: license),
          ],
          if (licenseExpiry != null) ...[
            SizedBox(height: 10.h),
            _InfoRow(
                icon: Icons.event_rounded,
                label: 'License Expiry',
                value: licenseExpiry),
          ],
        ],
      ),
    );
  }
}

// ─── Vehicle card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final String driverId;
  final bool isActionLoading;
  const _VehicleCard({
    required this.driver,
    required this.driverId,
    required this.isActionLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accent = isDark ? AppColors.accent : AppLightColors.accent;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final error = isDark ? AppColors.error : AppLightColors.error;

    final vehicle = driver['vehicle'] as Map<String, dynamic>?;
    final hasVehicle = vehicle != null;
    final plate = vehicle?['reg_number'] as String? ?? '—';
    final type = vehicle?['type'] as String? ?? '—';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_rounded,
                  color: accent, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                'ASSIGNED VEHICLE',
                style: TextStyle(
                  color: accent,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (hasVehicle) ...[
            Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: primary, size: 22.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plate,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                            color: textSecondary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: isActionLoading
                      ? null
                      : () => _confirmRemove(context, error),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: error.withOpacity(0.5)),
                    foregroundColor: error,
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text('Remove',
                      style: TextStyle(
                          fontSize: 11.sp, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: divider.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: textSecondary, size: 22.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'No vehicle assigned',
                    style: TextStyle(
                        color: textSecondary, fontSize: 13.sp),
                  ),
                ),
                ElevatedButton(
                  onPressed: isActionLoading
                      ? null
                      : () => _showAssignSheet(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child:
                      Text('Assign', style: TextStyle(fontSize: 11.sp)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Color error) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surface : AppLightColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Remove Vehicle',
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimary
                : AppLightColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'The vehicle will be unlinked from this driver. The driver will need a vehicle reassigned before going online.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondary
                : AppLightColors.textSecondary,
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(
                  color: error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DriverDetailCubit>().removeVehicle(driverId);
    }
  }

  Future<void> _showAssignSheet(BuildContext context) async {
    context.read<OwnerVehiclesCubit>().fetchVehicles();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AssignVehicleSheet(
        driverId: driverId,
        onAssigned: () => Navigator.pop(sheetCtx),
      ),
    );
  }
}

// ─── Assign vehicle bottom sheet ──────────────────────────────────────────────

class _AssignVehicleSheet extends StatelessWidget {
  final String driverId;
  final VoidCallback onAssigned;
  const _AssignVehicleSheet(
      {required this.driverId, required this.onAssigned});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppLightColors.surface;
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final error = isDark ? AppColors.error : AppLightColors.error;
    final accent = isDark ? AppColors.accent : AppLightColors.accent;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Assign Vehicle',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Tap a vehicle to assign it to this driver',
            style: TextStyle(color: textSecondary, fontSize: 12.sp),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
              builder: (ctx, state) {
                if (state is OwnerVehiclesLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2.5),
                  );
                }
                if (state is OwnerVehiclesError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(color: error, fontSize: 13.sp),
                    ),
                  );
                }
                if (state is OwnerVehiclesLoaded) {
                  if (state.vehicles.isEmpty) {
                    return Center(
                      child: Text(
                        'No vehicles found.\nAdd a vehicle first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textSecondary, fontSize: 13.sp),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.vehicles.length,
                    itemBuilder: (_, i) {
                      final v = state.vehicles[i];
                      final vid = v['id']?.toString() ??
                          v['vehicle_id']?.toString() ??
                          '';
                      final plate = v['reg_number'] as String? ?? '—';
                      final type = v['type'] as String? ?? '—';
                      final capacityRaw = v['capacity_kg'] ?? v['capacity'];
                      final capacity = capacityRaw?.toString();
                      final assignedDriver =
                          v['assigned_driver'] as Map<String, dynamic>?;
                      final isAssigned = assignedDriver != null;
                      final assignedName =
                          assignedDriver?['name'] as String? ?? '';
                      final badgeColor =
                          isAssigned ? error : AppColors.success;
                      final badgeLabel =
                          isAssigned ? 'ASSIGNED' : 'AVAILABLE';
                      final iconColor = isAssigned ? error : primary;

                      return GestureDetector(
                        onTap: () async {
                          if (vid.isEmpty) return;
                          if (isAssigned) {
                            final confirmed = await showDialog<bool>(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                backgroundColor: isDark
                                    ? AppColors.surface
                                    : AppLightColors.surface,
                                title: Text(
                                  'Reassign Vehicle?',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  '$plate is currently assigned to $assignedName. '
                                  'Reassigning will remove it from them.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(_, false),
                                    child: Text('Cancel',
                                        style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 13.sp)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(_, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: error,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Reassign',
                                        style:
                                            TextStyle(fontSize: 13.sp)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                          }
                          // ignore: use_build_context_synchronously
                          ctx
                              .read<DriverDetailCubit>()
                              .assignVehicle(driverId, vid);
                          onAssigned();
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: isAssigned
                                    ? error.withOpacity(0.3)
                                    : divider,
                                width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.directions_car_rounded,
                                  color: iconColor,
                                  size: 20.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plate,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      capacity != null
                                          ? '${type.toUpperCase()} · ${capacity}kg'
                                          : type.toUpperCase(),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                    if (isAssigned && assignedName.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Driver: $assignedName',
                                        style: TextStyle(
                                          color: error.withOpacity(0.8),
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
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

// ─── Status control ───────────────────────────────────────────────────────────

class _StatusControlCard extends StatelessWidget {
  final String currentStatus;
  final bool isActive;
  final bool isSuspended;
  final bool isLoading;
  final VoidCallback onActivate;
  final VoidCallback onSuspend;

  const _StatusControlCard({
    required this.currentStatus,
    required this.isActive,
    required this.isSuspended,
    required this.isLoading,
    required this.onActivate,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final error = isDark ? AppColors.error : AppLightColors.error;

    final isCreated =
        !isActive && !isSuspended && currentStatus != 'rejected';

    final statusColor = isActive
        ? AppColors.success
        : isSuspended
            ? error
            : textSecondary;
    final borderColor = isActive
        ? AppColors.success.withOpacity(0.3)
        : isSuspended
            ? error.withOpacity(0.3)
            : divider;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : isSuspended
                          ? Icons.block_rounded
                          : Icons.hourglass_top_rounded,
                  color: statusColor,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? 'Driver is Active'
                          : isSuspended
                              ? 'Driver is Suspended'
                              : 'Driver Created — Pending Activation',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isActive
                          ? 'Can go online and receive deliveries'
                          : isSuspended
                              ? 'Cannot go online or receive deliveries'
                              : 'Assign a vehicle and activate to enable',
                      style: TextStyle(
                          color: textSecondary, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(color: divider, height: 1),
          SizedBox(height: 14.h),
          if (!isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onActivate,
                icon: Icon(Icons.play_circle_rounded, size: 16.r),
                label: Text(
                    isCreated ? 'Activate Driver' : 'Reactivate Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onSuspend,
                icon: Icon(Icons.pause_circle_rounded,
                    size: 16.r, color: error),
                label: Text('Suspend Driver',
                    style: TextStyle(color: error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: error.withOpacity(0.4)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Performance row ──────────────────────────────────────────────────────────

class _PerformanceRow extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _PerformanceRow({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = isDark ? AppColors.error : AppLightColors.error;
    final accent = isDark ? AppColors.accent : AppLightColors.accent;

    final perf = driver['performance'] as Map<String, dynamic>? ??
        driver['stats'] as Map<String, dynamic>? ??
        {};
    final acceptanceRate =
        (perf['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
    final missedJobs = (perf['missed_jobs'] as num?)?.toInt() ?? 0;
    final completedJobs = (perf['completed_jobs'] as num?)?.toInt() ?? 0;
    final totalJobs = (perf['total_jobs'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _PerfMetric(
            label: 'Acceptance',
            value: '${acceptanceRate.toStringAsFixed(1)}%',
            icon: Icons.thumb_up_rounded,
            color: acceptanceRate >= 80 ? AppColors.success : (isDark ? AppColors.warning : AppLightColors.warning),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _PerfMetric(
            label: 'Completed',
            value: completedJobs.toString(),
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _PerfMetric(
            label: 'Missed',
            value: missedJobs.toString(),
            icon: Icons.cancel_rounded,
            color: missedJobs == 0 ? AppColors.success : error,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _PerfMetric(
            label: 'Total',
            value: totalJobs.toString(),
            icon: Icons.receipt_long_rounded,
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _PerfMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _PerfMetric(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppLightColors.card;
    final divider = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.r),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppLightColors.accent;
    return Text(
      label,
      style: TextStyle(
        color: accent,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Row(
      children: [
        Icon(icon, color: textSecondary, size: 15.r),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(color: textSecondary, fontSize: 12.sp),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _color(String s, bool isDark) => switch (s) {
        'active' => AppColors.success,
        'suspended' || 'disabled' || 'rejected' =>
          isDark ? AppColors.error : AppLightColors.error,
        _ => isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
      };

  String _label(String s) => switch (s) {
        'active' => 'ACTIVE',
        'pending_admin' => 'CREATED',
        'suspended' => 'SUSPENDED',
        'disabled' => 'DISABLED',
        'rejected' => 'REJECTED',
        _ => s.toUpperCase().replaceAll('_', ' '),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _color(status, isDark);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
            color: c, fontSize: 9.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final bool isOnline;
  const _OnlineBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final color = isOnline ? AppColors.success : textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.r,
            height: 5.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
