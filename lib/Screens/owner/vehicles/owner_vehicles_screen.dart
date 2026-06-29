import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import '../../../Bloc/OwnerVehicles/owner_vehicles_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

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
    // Auto-open the add sheet when navigated here via the "Add Vehicle" action.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['openAdd'] == true && mounted) {
        _showAddVehicleSheet(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: SosAppBar(
        title: 'Vehicles',
        centerTitle: true,
        actions: [
          BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
            builder: (_, s) => IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20.r),
              onPressed: s is OwnerVehiclesLoading
                  ? null
                  : () => context.read<OwnerVehiclesCubit>().fetchVehicles(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleSheet(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: Icon(Icons.add_rounded, size: 18.r),
        label: Text('Add Vehicle',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      ),
      body: BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
        builder: (ctx, state) {
          if (state is OwnerVehiclesInitial || state is OwnerVehiclesLoading) {
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: SkeletonBox(height: 90.h, radius: AppDesignTokens.radiusCard),
              ),
            );
          }
          if (state is OwnerVehiclesError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<OwnerVehiclesCubit>().fetchVehicles(),
            );
          }
          if (state is OwnerVehiclesLoaded) {
            if (state.vehicles.isEmpty) {
              return EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'No vehicles yet',
                subtitle: 'Add your first vehicle to start assigning to drivers.',
                actionLabel: 'Add Vehicle',
                onAction: () => _showAddVehicleSheet(context),
              );
            }
            return RefreshIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              onRefresh: () => context.read<OwnerVehiclesCubit>().fetchVehicles(),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
                itemCount: state.vehicles.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _VehicleTile(
                    vehicle: state.vehicles[i],
                    onEdit: () => _showAddVehicleSheet(
                      context,
                      vehicle: state.vehicles[i],
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAddVehicleSheet(
    BuildContext context, {
    Map<String, dynamic>? vehicle,
  }) {
    final isEdit = vehicle != null;

    String fieldText(String key) {
      final v = vehicle?[key];
      return v == null ? '' : v.toString();
    }

    final regCtr        = TextEditingController(text: fieldText('reg_number'));
    final nameCtr       = TextEditingController(text: fieldText('vehicle_name'));
    final rcNumberCtr    = TextEditingController(text: fieldText('rc_number'));
    final capacityCtr   = TextEditingController(text: fieldText('capacity_kg'));
    final minFeeCtr     = TextEditingController(text: fieldText('minimum_fee'));
    final includedKmCtr = TextEditingController(
        text: isEdit ? fieldText('included_distance_km') : '25');
    final perKmFeeCtr   = TextEditingController(text: fieldText('per_km_fee'));
    final maxDistCtr    = TextEditingController(
        text: fieldText('max_delivery_distance_km'));
    final gstPctCtr     = TextEditingController(
        text: isEdit ? fieldText('logistic_gst_percent') : '12');
    const vehicleTypes  = ['bike', 'three_wheeler', 'mini_truck', 'truck', 'reefer'];
    final initialType   = (vehicle?['type'] as String?)?.toLowerCase();
    String selectedType =
        (initialType != null && vehicleTypes.contains(initialType))
            ? initialType
            : 'bike';

    String? imageFrontPath;
    String? imageBackPath;
    String? insuranceDocPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final colorScheme = Theme.of(sheetCtx).colorScheme;

          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                            color: colorScheme.outline,
                            borderRadius: BorderRadius.circular(2.r)),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle',
                        style: Theme.of(sheetCtx).textTheme.titleLarge),
                    Text(
                        isEdit
                            ? 'Update this vehicle\'s details'
                            : 'Register a new vehicle to your fleet',
                        style: Theme.of(sheetCtx).textTheme.bodySmall),
                    SizedBox(height: 16.h),
                    SosTextField(
                      label: 'Registration Number',
                      controller: regCtr,
                      enabled: !isEdit,
                      prefixIcon: Icons.pin_rounded,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label: 'Vehicle Name (optional)',
                      controller: nameCtr,
                      prefixIcon: Icons.directions_car_outlined,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label: 'Vehicle RC Number',
                      controller: rcNumberCtr,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.numbers_rounded,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label: 'Capacity (kg)',
                      controller: capacityCtr,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.scale_outlined,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label:
                          'Minimum charge (covers included distance) (${AppConstants.currencySymbol})',
                      controller: minFeeCtr,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee_rounded,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label: 'Included distance (km) - covered by min charge',
                      controller: includedKmCtr,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.straighten_rounded,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Minimum charge covers the included distance; per-km applies beyond it, up to max distance.',
                      style: Theme.of(sheetCtx).textTheme.labelSmall,
                    ),
                    SizedBox(height: 8.h),
                    SosTextField(
                      label:
                          'Per-km charge (beyond included distance) (${AppConstants.currencySymbol})',
                      controller: perKmFeeCtr,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee_rounded,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label: 'Logistic GST %',
                      controller: gstPctCtr,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.percent_rounded,
                    ),
                    SizedBox(height: 12.h),
                    SosTextField(
                      label: 'Max delivery distance (km)',
                      controller: maxDistCtr,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.route_rounded,
                    ),
                    SizedBox(height: 12.h),
                    Text('Vehicle Type',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      children: vehicleTypes.map((t) {
                        final sel = selectedType == t;
                        final primary = colorScheme.primary;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedType = t),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: sel
                                  ? primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                  color: sel ? primary : colorScheme.outline),
                            ),
                            child: Text(t.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: sel
                                      ? primary
                                      : AppTheme.textSecondary(sheetCtx),
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    Text('Vehicle Photos',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    _PhotoPickerTile(
                      label: 'Vehicle Photo - Front',
                      path: imageFrontPath,
                      onTap: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                            source: ImageSource.gallery);
                        if (file != null) {
                          setSheetState(() => imageFrontPath = file.path);
                        }
                      },
                    ),
                    SizedBox(height: 10.h),
                    _PhotoPickerTile(
                      label: 'Vehicle Photo - Back',
                      path: imageBackPath,
                      onTap: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                            source: ImageSource.gallery);
                        if (file != null) {
                          setSheetState(() => imageBackPath = file.path);
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text('Insurance Document (optional)',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    _PhotoPickerTile(
                      label: 'Insurance - Upload',
                      path: insuranceDocPath,
                      onTap: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                            source: ImageSource.gallery);
                        if (file != null) {
                          setSheetState(() => insuranceDocPath = file.path);
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    SosButton(
                      label: isEdit ? 'Save Changes' : 'Add Vehicle',
                      onPressed: () {
                        final reg = regCtr.text.trim();
                        if (!isEdit && reg.isEmpty) return;
                        final rcNumber = rcNumberCtr.text.trim();
                        if (!isEdit) {
                          if (rcNumber.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vehicle RC number is required.'),
                              ),
                            );
                            return;
                          }
                          if (imageFrontPath == null || imageBackPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please add both front and back vehicle photos.'),
                              ),
                            );
                            return;
                          }
                        }
                        final minFee     = double.tryParse(minFeeCtr.text.trim());
                        final includedKm = double.tryParse(includedKmCtr.text.trim());
                        final perKm      = double.tryParse(perKmFeeCtr.text.trim());
                        final gstPct     = double.tryParse(gstPctCtr.text.trim());
                        final maxDist    = double.tryParse(maxDistCtr.text.trim());
                        if (minFee == null || minFee < 0 ||
                            includedKm == null || includedKm < 0 ||
                            perKm == null || perKm < 0 ||
                            gstPct == null || gstPct < 0 || gstPct > 100 ||
                            maxDist == null || maxDist < 0 ||
                            maxDist < includedKm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter valid values. GST must be 0-100. Max distance must be at least the included distance.',
                              ),
                            ),
                          );
                          return;
                        }
                        final cap = double.tryParse(capacityCtr.text.trim());
                        Navigator.pop(sheetCtx);
                        if (isEdit) {
                          context.read<OwnerVehiclesCubit>().updateVehicle(
                            vehicleId: vehicle['id'] as int,
                            type: selectedType,
                            capacityKg: cap,
                            minimumFee: minFee,
                            includedDistanceKm: includedKm,
                            perKmFee: perKm,
                            logisticGstPercent: gstPct,
                            maxDeliveryDistanceKm: maxDist,
                          );
                        } else {
                          final name = nameCtr.text.trim();
                          context.read<OwnerVehiclesCubit>().addVehicle(
                            regNumber: reg,
                            type: selectedType,
                            vehicleName: name.isEmpty ? null : name,
                            rcNumber: rcNumber,
                            imageFrontPath: imageFrontPath,
                            imageBackPath: imageBackPath,
                            insuranceDocPath: insuranceDocPath,
                            capacityKg: cap,
                            minimumFee: minFee,
                            includedDistanceKm: includedKm,
                            perKmFee: perKm,
                            logisticGstPercent: gstPct,
                            maxDeliveryDistanceKm: maxDist,
                          );
                        }
                      },
                    ),
                  ],
                ),
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
  final VoidCallback onEdit;
  const _VehicleTile({required this.vehicle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final regNum        = vehicle['reg_number'] as String? ?? '—';
    final type          = (vehicle['type'] as String? ?? 'vehicle').toUpperCase();
    final assignedDriver = vehicle['assigned_driver'] as Map<String, dynamic>?;
    final driverName    = assignedDriver?['name'] as String? ?? 'Unassigned';
    final isAssigned    = assignedDriver != null;
    final capacityKg    = vehicle['capacity_kg'];
    final insuranceExpiry = vehicle['insurance_expiry'] as String?;
    final minimumFee    = vehicle['minimum_fee'];
    final perKmFee      = vehicle['per_km_fee'];
    final maxDist       = vehicle['max_delivery_distance_km'];

    return SosCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppDesignTokens.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.directions_car_rounded,
                color: AppDesignTokens.warning, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regNum,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2.h),
                Text(type,
                    style: Theme.of(context).textTheme.labelSmall),
                if (capacityKg != null) ...[
                  SizedBox(height: 2.h),
                  Text('Capacity: ${capacityKg}kg',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
                if (minimumFee != null || perKmFee != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    [
                      if (minimumFee != null)
                        'Min ${AppConstants.currencySymbol}$minimumFee',
                      if (perKmFee != null)
                        '${AppConstants.currencySymbol}$perKmFee/km',
                      if (maxDist != null) '≤${maxDist}km',
                    ].join(' · '),
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondary(context)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SosChip(
                label: isAssigned ? 'ASSIGNED' : 'AVAILABLE',
                tone: isAssigned ? SosTone.success : SosTone.neutral,
              ),
              if (isAssigned) ...[
                SizedBox(height: 3.h),
                Text(driverName,
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondary(context))),
              ],
              if (insuranceExpiry != null) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 10.r,
                        color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    SizedBox(width: 3.w),
                    Text(insuranceExpiry,
                        style: TextStyle(
                            fontSize: 9.sp,
                            color: AppTheme.textSecondary(context))),
                  ],
                ),
              ],
            ],
          ),
          SizedBox(width: 4.w),
          IconButton(
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
            tooltip: 'Edit vehicle',
            icon: Icon(Icons.edit_outlined,
                size: 18.r,
                color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Photo picker tile ────────────────────────────────────────────────────────

class _PhotoPickerTile extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onTap;
  const _PhotoPickerTile({
    required this.label,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SosCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          if (path != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Image.file(
                File(path!),
                height: 40.r,
                width: 52.r,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(Icons.add_a_photo_outlined,
                color: AppTheme.textSecondary(context), size: 24.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              path != null ? '$label selected' : 'Upload $label',
              style: TextStyle(
                color: path != null
                    ? AppDesignTokens.success
                    : AppTheme.textSecondary(context),
                fontSize: 13.sp,
              ),
            ),
          ),
          if (path != null)
            Icon(Icons.check_circle,
                color: AppDesignTokens.success, size: 18.r),
        ],
      ),
    );
  }
}
