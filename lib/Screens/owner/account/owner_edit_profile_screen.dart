import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../Bloc/OwnerProfile/owner_profile_cubit.dart';
import '../../../Bloc/OwnerProfile/owner_profile_state.dart';
import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';

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
    final g = (owner['gender'] ?? '').toString();
    if (g.isNotEmpty && _genderOptions.contains(g)) {
      setState(() => _selectedGender = g);
    }
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final primaryColor = isDark ? AppColors.primaryLight : AppLightColors.primary;
    final textPrimary  = isDark ? AppColors.textPrimary  : AppLightColors.textPrimary;

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
          Divider(height: 1, color: isDark ? AppColors.divider : AppLightColors.divider),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor      = isDark ? AppColors.background    : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface       : AppLightColors.surface;
    final primaryColor = isDark ? AppColors.primaryLight  : AppLightColors.primary;
    final textPrimary  = isDark ? AppColors.textPrimary   : AppLightColors.textPrimary;
    final textSecondary= isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final dividerColor = isDark ? AppColors.divider       : AppLightColors.divider;
    final cardColor    = isDark ? AppColors.card          : AppLightColors.card;

    return BlocListener<OwnerProfileCubit, OwnerProfileState>(
      listener: (context, state) {
        if (state is OwnerProfileLoaded) _populate(state.data);
        if (state is OwnerProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pop(context, true);
        }
        if (state is OwnerProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20.r, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<OwnerProfileCubit, OwnerProfileState>(
          builder: (context, state) {
            if (state is OwnerProfileLoading) {
              return SizedBox(
                height: 400.h,
                child: Center(
                    child: CircularProgressIndicator(color: primaryColor)),
              );
            }

            final isSaving = state is OwnerProfileUpdating;

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
                                color: primaryColor.withOpacity(0.12),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
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
                                  size: 14.r, color: Colors.white),
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

                    _label('Full Name', textPrimary),
                    _field(
                      controller: _nameCtrl,
                      icon: Icons.person_outline,
                      hint: 'Your full name',
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      validator: (v) =>
                          (v == null || v.trim().length < 2)
                              ? 'Name must be at least 2 characters'
                              : null,
                    ),

                    _label('Gender', textPrimary),
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

                    _label('Flat / Building / Street', textPrimary),
                    _field(
                      controller: _addressLineCtrl,
                      icon: Icons.home_outlined,
                      hint: 'e.g. 12B, Rose Apartments, MG Road',
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                    ),

                    _label('Area / Locality', textPrimary),
                    _field(
                      controller: _areaCtrl,
                      icon: Icons.place_outlined,
                      hint: 'e.g. Koramangala',
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                    ),

                    SizedBox(height: 14.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('City', textPrimary),
                              _field(
                                controller: _cityCtrl,
                                icon: Icons.location_city_outlined,
                                hint: 'e.g. Bangalore',
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                dividerColor: dividerColor,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'City is required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State', textPrimary),
                              _field(
                                controller: _stateCtrl,
                                icon: Icons.map_outlined,
                                hint: 'e.g. Karnataka',
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                dividerColor: dividerColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _label('Pincode', textPrimary),
                    _field(
                      controller: _pincodeCtrl,
                      icon: Icons.pin_drop_outlined,
                      hint: 'e.g. 560034',
                      keyboardType: TextInputType.number,
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Pincode is required';
                        if (v.trim().length < 4) return 'Enter a valid pincode';
                        return null;
                      },
                    ),

                    SizedBox(height: 32.h),

                    // ── Save ─────────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // ── Danger Zone ───────────────────────────────────────────
                    _sectionHeader('Danger Zone', const Color(0xFFDC2626)),
                    SizedBox(height: 10.h),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(0.2)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFDC2626)),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '30-day grace period before permanent deletion',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFFDC2626).withOpacity(0.7)),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFDC2626)),
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
      value: _selectedGender,
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

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color primaryColor,
    required Color cardColor,
    required Color dividerColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: cardColor,
        prefixIcon: Icon(icon, size: 20.r, color: primaryColor),
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFDC2626))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
      ),
    );
  }

  // ── Delete account ────────────────────────────────────────────────────────────
  Future<void> _showDeleteAccountDialog(Color primaryColor) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary  = isDark ? AppColors.textPrimary  : AppLightColors.textPrimary;
    final textSecondary= isDark ? AppColors.textSecondary: AppLightColors.textSecondary;

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
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626), size: 28),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Color(0xFFDC2626)),
                  decoration: InputDecoration(
                    hintText: 'Type CONFIRM to proceed',
                    hintStyle: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0,
                        color: textSecondary),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.card : AppLightColors.card,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                            color: Color(0xFFDC2626))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(
                            color: const Color(0xFFDC2626).withOpacity(0.4))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(
                            color: Color(0xFFDC2626), width: 2)),
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
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canDelete
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFDC2626).withOpacity(0.3),
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            canDelete ? () => Navigator.pop(dCtx, true) : null,
                        child: const Text('Delete'),
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
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
