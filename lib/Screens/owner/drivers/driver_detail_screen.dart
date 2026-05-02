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
            backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.background,
            appBar: AppBar(
                backgroundColor: AppColors.surface,
                leading: BackButton(color: AppColors.textSecondary),
                title: const Text('Driver Detail')),
            body: const Center(
                child:
                    CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        if (state is DriverDetailError && _resolveDriver(state) == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
                backgroundColor: AppColors.surface,
                leading: BackButton(color: AppColors.textSecondary),
                title: const Text('Driver Detail')),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.error, size: 40.r),
                    SizedBox(height: 12.h),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13.sp)),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                        onPressed: () => context
                            .read<DriverDetailCubit>()
                            .fetchDriver(widget.driverId),
                        child: const Text('Retry')),
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            leading: BackButton(color: AppColors.textSecondary),
            title: Text(name),
            actions: [
              if (isActionLoading)
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Driver info card ──────────────────────────────────
                _DriverInfoCard(driver: driver),
                SizedBox(height: 16.h),

                // ── Vehicle card ──────────────────────────────────────
                _VehicleCard(
                  driver: driver,
                  driverId: widget.driverId,
                  isActionLoading: isActionLoading,
                ),
                SizedBox(height: 16.h),

                // ── Status control ────────────────────────────────────
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
                    confirmColor: AppColors.error,
                    onConfirm: () => context
                        .read<DriverDetailCubit>()
                        .setStatus(widget.driverId, 'suspended'),
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Performance ───────────────────────────────────────
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
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text(title,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600)),
        content: Text(message,
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel,
                  style: TextStyle(
                      color: confirmColor, fontWeight: FontWeight.w600))),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22.sp),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13.r,
                      height: 13.r,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.success
                            : AppColors.divider,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.card, width: 2),
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
                    Text(name,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700)),
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
          Divider(color: AppColors.divider, height: 1),
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
    final vehicle = driver['vehicle'] as Map<String, dynamic>?;
    final hasVehicle = vehicle != null;
    final plate = vehicle?['reg_number'] as String? ?? '—';
    final type = vehicle?['type'] as String? ?? '—';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_rounded,
                  color: AppColors.accent, size: 16.r),
              SizedBox(width: 6.w),
              Text('ASSIGNED VEHICLE',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
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
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: AppColors.primary, size: 22.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plate,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700)),
                      Text(type.toUpperCase(),
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: isActionLoading
                      ? null
                      : () => _confirmRemove(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    foregroundColor: AppColors.error,
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
                    color: AppColors.divider.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: AppColors.textSecondary, size: 22.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text('No vehicle assigned',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13.sp)),
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
                  child: Text('Assign',
                      style: TextStyle(fontSize: 11.sp)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text('Remove Vehicle',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600)),
        content: Text(
            'The vehicle will be unlinked from this driver. The driver will need a vehicle reassigned before going online.',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Remove',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DriverDetailCubit>().removeVehicle(driverId);
    }
  }

  Future<void> _showAssignSheet(BuildContext context) async {
    // Fetch vehicles before showing
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
    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Assign Vehicle',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700)),
          Text('Select a vehicle to assign to this driver',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.sp)),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
              builder: (_, state) {
                if (state is OwnerVehiclesLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent));
                }
                if (state is OwnerVehiclesError) {
                  return Center(
                      child: Text(state.message,
                          style: TextStyle(
                              color: AppColors.error, fontSize: 13.sp)));
                }
                if (state is OwnerVehiclesLoaded) {
                  if (state.vehicles.isEmpty) {
                    return Center(
                      child: Text('No vehicles found.\nAdd a vehicle first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.sp)),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.vehicles.length,
                    itemBuilder: (_, i) {
                      final v = state.vehicles[i];
                      final vid = v['id']?.toString() ??
                          v['vehicle_id']?.toString() ??
                          '';
                      final plate =
                          v['reg_number'] as String? ?? '—';
                      final type =
                          v['type'] as String? ?? '—';
                      return GestureDetector(
                        onTap: () {
                          if (vid.isEmpty) return;
                          context
                              .read<DriverDetailCubit>()
                              .assignVehicle(driverId, vid);
                          onAssigned();
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(12.r),
                            border: Border.all(
                                color: AppColors.divider, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                    Icons.directions_car_rounded,
                                    color: AppColors.primary,
                                    size: 18.r),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(plate,
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14.sp,
                                            fontWeight:
                                                FontWeight.w600)),
                                    Text(
                                        type.toUpperCase(),
                                        style: TextStyle(
                                            color:
                                                AppColors.textSecondary,
                                            fontSize: 11.sp)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: AppColors.divider, size: 18.r),
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
    // created (pending_admin) state — must activate first
    final isCreated =
        !isActive && !isSuspended && currentStatus != 'rejected';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.3)
              : isSuspended
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.divider,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: (isActive
                          ? AppColors.success
                          : isSuspended
                              ? AppColors.error
                              : AppColors.textSecondary)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : isSuspended
                          ? Icons.block_rounded
                          : Icons.hourglass_top_rounded,
                  color: isActive
                      ? AppColors.success
                      : isSuspended
                          ? AppColors.error
                          : AppColors.textSecondary,
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
                          color: AppColors.textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isActive
                          ? 'Can go online and receive deliveries'
                          : isSuspended
                              ? 'Cannot go online or receive deliveries'
                              : 'Assign a vehicle and activate to enable',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(color: AppColors.divider, height: 1),
          SizedBox(height: 14.h),
          if (!isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onActivate,
                icon: Icon(Icons.play_circle_rounded, size: 16.r),
                label: Text(isCreated ? 'Activate Driver' : 'Reactivate Driver'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
              ),
            ),
          if (isActive) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onSuspend,
                icon: Icon(Icons.pause_circle_rounded,
                    size: 16.r, color: AppColors.error),
                label: Text('Suspend Driver',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
          ],
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
    final perf = driver['performance'] as Map<String, dynamic>? ??
        driver['stats'] as Map<String, dynamic>? ??
        {};
    final acceptanceRate =
        (perf['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
    final missedJobs = perf['missed_jobs'] as int? ?? 0;
    final completedJobs = perf['completed_jobs'] as int? ?? 0;
    final totalJobs = perf['total_jobs'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _PerfMetric(
            label: 'Acceptance',
            value: '${acceptanceRate.toStringAsFixed(1)}%',
            icon: Icons.thumb_up_rounded,
            color: acceptanceRate >= 80
                ? AppColors.success
                : AppColors.warning,
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
            color:
                missedJobs == 0 ? AppColors.success : AppColors.error,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _PerfMetric(
            label: 'Total',
            value: totalJobs.toString(),
            icon: Icons.receipt_long_rounded,
            color: AppColors.accent,
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
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.r),
          SizedBox(height: 6.h),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 9.sp)),
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
    return Text(label,
        style: TextStyle(
            color: AppColors.accent,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
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
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 15.r),
        SizedBox(width: 8.w),
        Text('$label: ',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12.sp)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static Color _color(String s) => switch (s) {
        'active' => AppColors.success,
        'suspended' || 'disabled' || 'rejected' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  static String _label(String s) => switch (s) {
        'active' => 'ACTIVE',
        'pending_admin' => 'CREATED',
        'suspended' => 'SUSPENDED',
        'disabled' => 'DISABLED',
        'rejected' => 'REJECTED',
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

class _OnlineBadge extends StatelessWidget {
  final bool isOnline;
  const _OnlineBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: (isOnline ? AppColors.success : AppColors.textSecondary)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.r,
            height: 5.r,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: isOnline ? AppColors.success : AppColors.textSecondary,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
