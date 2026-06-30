import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../register/service_area_picker_screen.dart';

import '../../../Bloc/OwnerProfile/owner_profile_cubit.dart';
import '../../../Bloc/OwnerProfile/owner_profile_state.dart';
import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';
import '../../../utility/form_validators.dart';
import '../../../utility/pincode_autofill_field.dart';
import '../../../widgets/widgets.dart';

class OwnerEditProfileScreen extends StatefulWidget {
  const OwnerEditProfileScreen({super.key});

  @override
  State<OwnerEditProfileScreen> createState() => _OwnerEditProfileScreenState();
}

class _OwnerEditProfileScreenState extends State<OwnerEditProfileScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _addressLineCtrl = TextEditingController();
  final _areaCtrl        = TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _stateCtrl       = TextEditingController();
  final _pincodeCtrl     = TextEditingController();

  String? _selectedGender;
  File?   _imageFile;
  String  _existingPhotoUrl = '';
  bool    _populated = false;

  double? _serviceLat;
  double? _serviceLng;
  double? _serviceRadiusKm;

  final _picker = ImagePicker();

  static const _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    context.read<OwnerProfileCubit>().fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressLineCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> data) {
    if (_populated) return;
    _populated = true;
    final user  = data['user']  as Map?  ?? {};
    final owner = data['owner'] as Map?  ?? {};
    _nameCtrl.text        = (user['name']            ?? '').toString();
    _addressLineCtrl.text = (owner['address_line']   ?? '').toString();
    _areaCtrl.text        = (owner['area']           ?? '').toString();
    _cityCtrl.text        = (owner['city']           ?? '').toString();
    _stateCtrl.text       = (owner['state']          ?? '').toString();
    _pincodeCtrl.text     = (owner['pincode']        ?? '').toString();
    _existingPhotoUrl     = (owner['profile_photo_url'] ?? '').toString();
    double? toD(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    _serviceLat      = toD(owner['service_lat']);
    _serviceLng      = toD(owner['service_lng']);
    _serviceRadiusKm = toD(owner['service_radius_km']);
    // Backend stores gender lowercase ('male'); options are capitalized.
    // Match case-insensitively so the dropdown prefills correctly.
    final g = (owner['gender'] ?? '').toString();
    if (g.isNotEmpty) {
      final match = _genderOptions.firstWhere(
        (o) => o.toLowerCase() == g.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) setState(() => _selectedGender = match);
    }
  }

  Future<void> _pickImage() async {
    final scheme = Theme.of(context).colorScheme;
    final surfaceColor = scheme.surface;
    final primaryColor = scheme.primary;
    final textPrimary  = scheme.onSurface;

    await showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(children: [
              Icon(Icons.photo_outlined, color: primaryColor),
              SizedBox(width: 8.w),
              Text('Change Photo',
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
            ]),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: primaryColor),
            title: Text('Gallery',
                style: TextStyle(fontSize: 14.sp, color: textPrimary)),
            onTap: () async {
              Navigator.pop(ctx);
              final f = await _picker.pickImage(source: ImageSource.gallery);
              if (f != null) setState(() => _imageFile = File(f.path));
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: primaryColor),
            title: Text('Camera',
                style: TextStyle(fontSize: 14.sp, color: textPrimary)),
            onTap: () async {
              Navigator.pop(ctx);
              final f = await _picker.pickImage(source: ImageSource.camera);
              if (f != null) setState(() => _imageFile = File(f.path));
            },
          ),
          SizedBox(height: 8.h),
        ]),
      ),
    );
  }

  Future<void> _pickServiceArea() async {
    final initial = (_serviceLat != null && _serviceLng != null)
        ? LatLng(_serviceLat!, _serviceLng!)
        : null;
    final result = await Navigator.of(context).push<ServiceAreaResult>(
      MaterialPageRoute(
        builder: (_) => ServiceAreaPickerScreen(
          initial: initial,
          initialRadiusKm: _serviceRadiusKm,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _serviceLat = result.center.latitude;
        _serviceLng = result.center.longitude;
        _serviceRadiusKm = result.radiusKm;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<OwnerProfileCubit>().updateProfile(
      name:        _nameCtrl.text.trim(),
      gender:      _selectedGender,
      addressLine: _addressLineCtrl.text.trim(),
      area:        _areaCtrl.text.trim(),
      city:        _cityCtrl.text.trim(),
      state:       _stateCtrl.text.trim(),
      pincode:     _pincodeCtrl.text.trim(),
      photoPath:   _imageFile?.path,
      serviceLat:      _serviceLat,
      serviceLng:      _serviceLng,
      serviceRadiusKm: _serviceRadiusKm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<OwnerProfileCubit, OwnerProfileState>(
      listener: (context, state) {
        if (state is OwnerProfileLoaded) _populate(state.data);
        if (state is OwnerProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: scheme.primary,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pop(context, true);
        }
        if (state is OwnerProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        appBar: const SosAppBar(title: 'Edit Profile'),
        body: BlocBuilder<OwnerProfileCubit, OwnerProfileState>(
          builder: (context, state) {
            if (state is OwnerProfileLoading) {
              return SizedBox(
                height: 400.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final isSaving = state is OwnerProfileUpdating;
            final primaryColor = scheme.primary;
            final surfaceColor = scheme.surface;
            final textSecondary = AppTheme.textSecondary(context);
            final cardColor = AppTheme.card(context);
            final dividerColor = AppTheme.divider(context);

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ──────────────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100.r,
                              height: 100.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.12),
                                border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    width: 2),
                              ),
                              child: ClipOval(
                                child: _imageFile != null
                                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                                    : _existingPhotoUrl.isNotEmpty
                                        ? Image.network(_existingPhotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _initialsWidget(primaryColor))
                                        : _initialsWidget(primaryColor),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: surfaceColor, width: 2),
                              ),
                              child: Icon(Icons.camera_alt,
                                  size: 14.r, color: scheme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Center(
                      child: Text(
                        'Tap to change photo',
                        style: TextStyle(
                            fontSize: 12.sp, color: textSecondary),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── Personal Information ─────────────────────────────────
                    _sectionHeader('Personal Information', textSecondary),
                    SizedBox(height: 10.h),

                    SosTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline,
                      hint: 'Your full name',
                      validator: (v) =>
                          (v == null || v.trim().length < 2)
                              ? 'Name must be at least 2 characters'
                              : null,
                    ),
                    SizedBox(height: 12.h),

                    _label('Gender', AppTheme.textPrimary(context)),
                    _genderDropdown(
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      textSecondary: textSecondary,
                    ),

                    SizedBox(height: 24.h),

                    // ── Address ──────────────────────────────────────────────
                    _sectionHeader('Address', textSecondary),
                    SizedBox(height: 10.h),

                    SosTextField(
                      label: 'Flat / Building / Street',
                      controller: _addressLineCtrl,
                      prefixIcon: Icons.home_outlined,
                      hint: 'e.g. 12B, Rose Apartments, MG Road',
                    ),
                    SizedBox(height: 12.h),

                    SosTextField(
                      label: 'Area / Locality',
                      controller: _areaCtrl,
                      prefixIcon: Icons.place_outlined,
                      hint: 'e.g. Koramangala',
                    ),

                    SizedBox(height: 14.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SosTextField(
                            label: 'City',
                            controller: _cityCtrl,
                            prefixIcon: Icons.location_city_outlined,
                            hint: 'e.g. Bangalore',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'City is required'
                                    : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: SosTextField(
                            label: 'State',
                            controller: _stateCtrl,
                            prefixIcon: Icons.map_outlined,
                            hint: 'e.g. Karnataka',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),
                    _label('Pincode', AppTheme.textPrimary(context)),
                    PincodeAutofillField(
                      controller: _pincodeCtrl,
                      cityController: _cityCtrl,
                      stateController: _stateCtrl,
                      areaController: _areaCtrl,
                      validator: FormValidators.pincode,
                    ),

                    SizedBox(height: 24.h),
                    _sectionHeader('Service Area', textSecondary),
                    SizedBox(height: 4.h),
                    Text(
                      'The centre of the area you deliver in. You only receive '
                      'delivery requests with a pickup inside this circle.',
                      style: TextStyle(fontSize: 12.sp, color: textSecondary),
                    ),
                    SizedBox(height: 10.h),
                    _ServiceAreaCard(
                      lat: _serviceLat,
                      lng: _serviceLng,
                      radiusKm: _serviceRadiusKm,
                      onTap: _pickServiceArea,
                    ),

                    SizedBox(height: 32.h),

                    // ── Save ─────────────────────────────────────────────────
                    SosButton(
                      label: 'Save Changes',
                      loading: isSaving,
                      onPressed: isSaving ? null : _save,
                    ),

                    SizedBox(height: 32.h),

                    // ── Danger Zone ───────────────────────────────────────────
                    _sectionHeader('Danger Zone', scheme.error),
                    SizedBox(height: 10.h),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: scheme.error.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded,
                            color: scheme.error),
                        title: Text(
                          'Delete Account',
                          style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '30-day grace period before permanent deletion',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: scheme.error.withValues(alpha: 0.7)),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: scheme.error),
                        onTap: () => _showDeleteAccountDialog(primaryColor),
                      ),
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _initialsWidget(Color primaryColor) {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : 'O';
    return Center(
      child: Text(initial,
          style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w700,
              color: primaryColor)),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _label(String text, Color textPrimary) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h, bottom: 5.h),
      child: Text(text,
          style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: textPrimary)),
    );
  }

  Widget _genderDropdown({
    required Color primaryColor,
    required Color cardColor,
    required Color dividerColor,
    required Color textSecondary,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      dropdownColor: cardColor,
      hint: Row(children: [
        Icon(Icons.wc_outlined, size: 20.r, color: primaryColor),
        SizedBox(width: 12.w),
        Text('Select gender',
            style: TextStyle(fontSize: 14.sp, color: textSecondary)),
      ]),
      items: _genderOptions
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) => setState(() => _selectedGender = v),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        prefixIcon: Icon(Icons.wc_outlined, size: 20.r, color: primaryColor),
        contentPadding:
            EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: dividerColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }

  // ── Delete account ────────────────────────────────────────────────────────────
  Future<void> _showDeleteAccountDialog(Color primaryColor) async {
    final scheme = Theme.of(context).colorScheme;
    final surfaceColor = scheme.surface;
    final textPrimary  = scheme.onSurface;
    final textSecondary = AppTheme.textSecondary(context);

    final confirmCtrl = TextEditingController();
    bool canDelete = false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDs) => Dialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: scheme.error, size: 28),
                ),
                SizedBox(height: 12.h),
                Text('Delete Account',
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                SizedBox(height: 8.h),
                Text(
                  'Your account will enter a 30-day grace period. If you log in within 30 days, it will be automatically restored. After 30 days, the account will be permanently deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.sp, height: 1.5, color: textSecondary),
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: confirmCtrl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: scheme.error),
                  decoration: InputDecoration(
                    hintText: 'Type CONFIRM to proceed',
                    hintStyle: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0,
                        color: textSecondary),
                    filled: true,
                    fillColor: AppTheme.card(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: scheme.error)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(
                            color: scheme.error.withValues(alpha: 0.4))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(
                            color: scheme.error, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) =>
                      setDs(() => canDelete = v.trim() == 'CONFIRM'),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: SosButton(
                        label: 'Cancel',
                        variant: SosButtonVariant.outline,
                        onPressed: () => Navigator.pop(dCtx, false),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: SosButton(
                        label: 'Delete',
                        variant: SosButtonVariant.danger,
                        onPressed: canDelete
                            ? () => Navigator.pop(dCtx, true)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    confirmCtrl.dispose();

    if (shouldDelete == true && mounted) {
      final res = await ApiServiceV2.instance
          .post('owner/me/delete-account', data: {});
      if (!mounted) return;
      if (res['status'] == 'success') {
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] as String? ?? 'Failed. Try again.'),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

/// Tappable summary of the owner's account-wide service area. Set/unset states,
/// emerald radius pill, coordinate readout. Opens [ServiceAreaPickerScreen].
class _ServiceAreaCard extends StatelessWidget {
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final VoidCallback onTap;

  const _ServiceAreaCard({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSet = lat != null && lng != null;

    return SosCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isSet ? scheme.primary : scheme.onSurfaceVariant)
                      .withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.radar_rounded,
                  color: isSet ? scheme.primary : scheme.onSurfaceVariant,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSet ? 'Service area set' : 'Set your service area',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSet && radiusKm != null)
                          SosChip(label: '${radiusKm!.round()} km'),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isSet
                          ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                          : 'Tap to pick a centre point on the map',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
