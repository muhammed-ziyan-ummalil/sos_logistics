import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import '../../../Bloc/OwnerVehicles/owner_vehicles_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../utility/image_source_picker.dart';
import '../../../widgets/widgets.dart';

/// `vehicles.type` ENUM, in DB order. The backend rejects anything else, so the
/// picker and the server agree on exactly these keys.
const List<String> _vehicleTypeKeys = [
  'bike',
  'three_wheeler',
  'mini_truck',
  'truck',
  'reefer',
];

/// Human label for a changed column name, for the "awaiting approval" line.
String _changedFieldLabel(String key) {
  switch (key) {
    case 'type':
      return 'type';
    case 'capacity_kg':
      return 'capacity';
    case 'minimum_fee':
      return 'minimum fee';
    case 'per_km_fee':
      return 'per-km fee';
    case 'included_distance_km':
      return 'included distance';
    case 'logistic_gst_percent':
      return 'GST %';
    case 'insurance_expiry':
      return 'insurance expiry';
    case 'image_front_url':
      return 'front photo';
    case 'image_back_url':
      return 'back photo';
    case 'rc_doc_url':
      return 'RC document';
    case 'insurance_doc_url':
      return 'insurance document';
    default:
      return key;
  }
}

String _vehicleTypeLabel(String key) {
  switch (key) {
    case 'bike':
      return 'Bike';
    case 'three_wheeler':
      return 'Three Wheeler';
    case 'mini_truck':
      return 'Mini Truck';
    case 'truck':
      return 'Truck';
    case 'reefer':
      return 'Reefer (refrigerated)';
    default:
      return key;
  }
}

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
    final gstPctCtr     = TextEditingController(
        text: isEdit ? fieldText('logistic_gst_percent') : '12');
    // Vehicle type is a fixed set server-side (`vehicles.type` is an ENUM). It used
    // to be a free-text field, and because MySQL runs non-strict every unmatched
    // value was silently written as '' - which is why existing vehicles come back
    // with no type and an edit could not be saved. Pick from the enum only.
    String? selectedType = _vehicleTypeKeys.contains(fieldText('type'))
        ? fieldText('type')
        : null;

    String? imageFrontPath;
    String? imageBackPath;
    String? rcDocPath;
    String? insuranceDocPath;
    String? formError;

    // Existing uploaded media (edit mode) so the picker tiles preview the
    // current images. Stored as relative paths under the API host.
    String? existingMediaUrl(String key) {
      final p = vehicle?[key] as String?;
      if (p == null || p.isEmpty) return null;
      if (p.startsWith('http')) return p;
      return 'https://api.sossss.net/${p.replaceFirst(RegExp(r'^/+'), '')}';
    }

    // Dirty tracking: the Save Changes button (edit mode) is disabled until a
    // field is changed or a new image is picked.
    final dirty = ValueNotifier<bool>(false);
    bool computeDirty() {
      if (imageFrontPath != null ||
          imageBackPath != null ||
          rcDocPath != null ||
          insuranceDocPath != null) {
        return true;
      }
      bool diff(TextEditingController c, String key, [String fallback = '']) {
        final init = isEdit ? fieldText(key) : fallback;
        return c.text.trim() != init.trim();
      }

      return (selectedType ?? '') != (isEdit ? fieldText('type') : '') ||
          diff(nameCtr, 'vehicle_name') ||
          diff(rcNumberCtr, 'rc_number') ||
          diff(capacityCtr, 'capacity_kg') ||
          diff(minFeeCtr, 'minimum_fee') ||
          diff(includedKmCtr, 'included_distance_km', '25') ||
          diff(perKmFeeCtr, 'per_km_fee') ||
          diff(gstPctCtr, 'logistic_gst_percent', '12');
    }

    if (isEdit) {
      for (final c in [
        nameCtr, rcNumberCtr, capacityCtr, minFeeCtr,
        includedKmCtr, perKmFeeCtr, gstPctCtr,
      ]) {
        c.addListener(() => dirty.value = computeDirty());
      }
    }

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
                      label: 'Vehicle Name',
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
                          'Minimum charge per kg/litre (covers included distance) (${AppConstants.currencySymbol})',
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
                      'Charges are per kg / litre: (minimum charge + per-km beyond the included distance) '
                      'is multiplied by the total order weight. e.g. ${AppConstants.currencySymbol}2 min + '
                      '${AppConstants.currencySymbol}1/km for 10 extra km = ${AppConstants.currencySymbol}12 per kg; '
                      'a 50 kg order = ${AppConstants.currencySymbol}600 (before GST).',
                      style: Theme.of(sheetCtx).textTheme.labelSmall,
                    ),
                    SizedBox(height: 8.h),
                    SosTextField(
                      label:
                          'Per-km charge per kg/litre (beyond included distance) (${AppConstants.currencySymbol})',
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
                    Text('Vehicle Type',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 6.h),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.local_shipping_outlined),
                        hintText: 'Select vehicle type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                      ),
                      items: _vehicleTypeKeys
                          .map((k) => DropdownMenuItem(
                                value: k,
                                child: Text(_vehicleTypeLabel(k)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setSheetState(() => selectedType = v);
                        dirty.value = computeDirty();
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text('Vehicle Photos',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    _PhotoPickerTile(
                      label: 'Vehicle Photo - Front',
                      path: imageFrontPath,
                      existingUrl: existingMediaUrl('image_front_url'),
                      onTap: () async {
                        final path = await pickImageWithSource(sheetCtx);
                        if (path != null) {
                          setSheetState(() => imageFrontPath = path);
                          dirty.value = computeDirty();
                        }
                      },
                    ),
                    SizedBox(height: 10.h),
                    _PhotoPickerTile(
                      label: 'Vehicle Photo - Back',
                      path: imageBackPath,
                      existingUrl: existingMediaUrl('image_back_url'),
                      onTap: () async {
                        final path = await pickImageWithSource(sheetCtx);
                        if (path != null) {
                          setSheetState(() => imageBackPath = path);
                          dirty.value = computeDirty();
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text('RC Document',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    _PhotoPickerTile(
                      label: 'RC Document - Upload',
                      path: rcDocPath,
                      existingUrl: existingMediaUrl('rc_doc_url'),
                      onTap: () async {
                        final path = await pickImageWithSource(sheetCtx);
                        if (path != null) {
                          setSheetState(() => rcDocPath = path);
                          dirty.value = computeDirty();
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text('Insurance Document',
                        style: Theme.of(sheetCtx).textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    _PhotoPickerTile(
                      label: 'Insurance - Upload',
                      path: insuranceDocPath,
                      existingUrl: existingMediaUrl('insurance_doc_url'),
                      onTap: () async {
                        final path = await pickImageWithSource(sheetCtx);
                        if (path != null) {
                          setSheetState(() => insuranceDocPath = path);
                          dirty.value = computeDirty();
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    if (formError != null) ...[
                      Text(
                        formError!,
                        style: TextStyle(
                            color: Theme.of(sheetCtx).colorScheme.error,
                            fontSize: 12.sp),
                      ),
                      SizedBox(height: 10.h),
                    ],
                    ValueListenableBuilder<bool>(
                      valueListenable: dirty,
                      builder: (context, isDirty, _) => SosButton(
                      label: isEdit ? 'Save Changes' : 'Add Vehicle',
                      onPressed: (isEdit && !isDirty)
                          ? null
                          : () {
                        setSheetState(() => formError = null);
                        final reg = regCtr.text.trim();
                        if (!isEdit && reg.isEmpty) return;
                        final rcNumber = rcNumberCtr.text.trim();
                        if (selectedType == null) {
                          setSheetState(() => formError = 'Select a vehicle type.');
                          return;
                        }
                        if (!isEdit) {
                          if (rcNumber.isEmpty) {
                            setSheetState(() => formError = 'Vehicle RC number is required.');
                            return;
                          }
                          if (imageFrontPath == null || imageBackPath == null) {
                            setSheetState(() => formError = 'Please add both front and back vehicle photos.');
                            return;
                          }
                          if (rcDocPath == null) {
                            setSheetState(() => formError = 'Please upload the RC document photo.');
                            return;
                          }
                          if (insuranceDocPath == null) {
                            setSheetState(() => formError = 'Please upload the insurance document photo.');
                            return;
                          }
                          if (nameCtr.text.trim().isEmpty) {
                            setSheetState(() => formError = 'Vehicle name is required.');
                            return;
                          }
                        }
                        final minFee     = double.tryParse(minFeeCtr.text.trim());
                        final includedKm = double.tryParse(includedKmCtr.text.trim());
                        final perKm      = double.tryParse(perKmFeeCtr.text.trim());
                        final gstPct     = double.tryParse(gstPctCtr.text.trim());
                        if (minFee == null || minFee < 0 ||
                            includedKm == null || includedKm < 0 ||
                            perKm == null || perKm < 0 ||
                            gstPct == null || gstPct < 0 || gstPct > 100) {
                          setSheetState(() => formError = 'Enter valid values. GST must be 0-100.');
                          return;
                        }
                        final cap = double.tryParse(capacityCtr.text.trim());
                        if (cap == null || cap <= 0) {
                          setSheetState(() => formError = 'Enter a valid capacity (kg).');
                          return;
                        }
                        Navigator.pop(sheetCtx);
                        if (isEdit) {
                          context.read<OwnerVehiclesCubit>().updateVehicle(
                            vehicleId: vehicle['id'] as int,
                            type: selectedType!,
                            capacityKg: cap,
                            minimumFee: minFee,
                            includedDistanceKm: includedKm,
                            perKmFee: perKm,
                            logisticGstPercent: gstPct,
                            imageFrontPath: imageFrontPath,
                            imageBackPath: imageBackPath,
                            rcDocPath: rcDocPath,
                            insuranceDocPath: insuranceDocPath,
                          );
                        } else {
                          final name = nameCtr.text.trim();
                          context.read<OwnerVehiclesCubit>().addVehicle(
                            regNumber: reg,
                            type: selectedType!,
                            vehicleName: name,
                            rcNumber: rcNumber,
                            imageFrontPath: imageFrontPath,
                            imageBackPath: imageBackPath,
                            rcDocPath: rcDocPath,
                            insuranceDocPath: insuranceDocPath,
                            capacityKg: cap,
                            minimumFee: minFee,
                            includedDistanceKm: includedKm,
                            perKmFee: perKm,
                            logisticGstPercent: gstPct,
                          );
                        }
                      },
                      ),
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
    final rawType       = (vehicle['type'] as String? ?? '').trim();
    final type = rawType.isEmpty
        ? 'TYPE NOT SET'
        : _vehicleTypeLabel(rawType).toUpperCase();
    // Fields the owner edited that the admin has not approved yet.
    final pendingChanges = vehicle['pending_changes'] is Map
        ? Map<String, dynamic>.from(vehicle['pending_changes'] as Map)
        : const <String, dynamic>{};
    final assignedDriver = vehicle['assigned_driver'] as Map<String, dynamic>?;
    final driverName    = assignedDriver?['name'] as String? ?? 'Unassigned';
    final isAssigned    = assignedDriver != null;
    final vStatus       = (vehicle['status'] as String?)?.toLowerCase() ?? 'active';
    final isPending     = vStatus == 'pending';
    final isInactive    = vStatus == 'inactive' || vStatus == 'maintenance';
    final rejectionReason = (vehicle['rejection_reason'] as String?)?.trim();
    final isRejected    = rejectionReason != null && rejectionReason.isNotEmpty;
    final capacityKg    = vehicle['capacity_kg'];
    final insuranceExpiry = vehicle['insurance_expiry'] as String?;
    final minimumFee    = vehicle['minimum_fee'];
    final perKmFee      = vehicle['per_km_fee'];

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
                    ].join(' · '),
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondary(context)),
                  ),
                ],
                if (isPending && pendingChanges.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Awaiting admin approval for: '
                    '${pendingChanges.keys.map(_changedFieldLabel).join(', ')}',
                    style: TextStyle(
                        fontSize: 10.sp, color: AppDesignTokens.warning),
                  ),
                ],
                if (isRejected) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Rejected: $rejectionReason',
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SosChip(
                label: isRejected
                    ? 'REJECTED'
                    : isPending
                        ? 'PENDING'
                        : isInactive
                            ? vStatus.toUpperCase()
                            : (isAssigned ? 'ASSIGNED' : 'AVAILABLE'),
                tone: isRejected
                    ? SosTone.error
                    : isPending
                        ? SosTone.warning
                        : isInactive
                            ? SosTone.neutral
                            : (isAssigned ? SosTone.success : SosTone.neutral),
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
  final String? existingUrl;
  final VoidCallback onTap;
  const _PhotoPickerTile({
    required this.label,
    required this.path,
    this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNew = path != null;
    final hasExisting = !hasNew && existingUrl != null && existingUrl!.isNotEmpty;

    Widget preview;
    if (hasNew) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Image.file(File(path!),
            height: 40.r, width: 52.r, fit: BoxFit.cover),
      );
    } else if (hasExisting) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Image.network(
          existingUrl!,
          height: 40.r,
          width: 52.r,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined,
              color: AppTheme.textSecondary(context), size: 24.r),
        ),
      );
    } else {
      preview = Icon(Icons.add_a_photo_outlined,
          color: AppTheme.textSecondary(context), size: 24.r);
    }

    final text = hasNew
        ? '$label - new photo selected'
        : hasExisting
            ? '$label - tap to replace'
            : 'Upload $label';

    return SosCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          preview,
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: (hasNew || hasExisting)
                    ? AppDesignTokens.success
                    : AppTheme.textSecondary(context),
                fontSize: 13.sp,
              ),
            ),
          ),
          if (hasNew)
            Icon(Icons.check_circle,
                color: AppDesignTokens.success, size: 18.r),
        ],
      ),
    );
  }
}
