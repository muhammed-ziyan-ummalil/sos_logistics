import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Bloc/OwnerDrivers/add_driver_cubit.dart';
import '../../../Bloc/OwnerDrivers/add_driver_state.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';
import 'temp_password_sheet.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtr    = TextEditingController();
  final _emailCtr   = TextEditingController();
  final _phoneCtr   = TextEditingController();
  final _licenseCtr = TextEditingController();

  DateTime? _licenseExpiry;
  String? _licenseDocPath;
  String? _idProofDocPath;

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _phoneCtr.dispose();
    _licenseCtr.dispose();
    super.dispose();
  }

  Future<void> _pickDoc(bool isLicense) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        if (isLicense) {
          _licenseDocPath = file.path;
        } else {
          _idProofDocPath = file.path;
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _licenseExpiry = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddDriverCubit>().createDriver(
      name: _nameCtr.text.trim(),
      email: _emailCtr.text.trim(),
      phone: _phoneCtr.text.trim(),
      licenseNumber: _licenseCtr.text.trim().isEmpty
          ? null
          : _licenseCtr.text.trim(),
      licenseDocPath: _licenseDocPath,
      idProofDocPath: _idProofDocPath,
      licenseExpiry: _licenseExpiry != null
          ? '${_licenseExpiry!.year}-'
              '${_licenseExpiry!.month.toString().padLeft(2, '0')}-'
              '${_licenseExpiry!.day.toString().padLeft(2, '0')}'
          : null,
    );
  }

  Widget _docPickerTile({
    required String label,
    required String? path,
    required VoidCallback onTap,
  }) {
    return SosCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          if (path != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Image.file(
                File(path),
                height: 40.r,
                width: 52.r,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(Icons.upload_file_rounded,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AddDriverCubit, AddDriverState>(
      listener: (ctx, state) {
        if (state is AddDriverSuccess) {
          showModalBottomSheet(
            context: ctx,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => TempPasswordSheet(
              tempPassword: state.tempPassword,
              onDismissed: () {
                Navigator.pop(ctx);
                context.read<AddDriverCubit>().reset();
                Navigator.pop(ctx, true);
              },
            ),
          );
        } else if (state is AddDriverError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const SosAppBar(title: 'Add Driver'),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Basic info ─────────────────────────────────────────
                _SectionLabel(label: 'DRIVER INFORMATION'),
                SizedBox(height: 10.h),
                SosTextField(
                  label: 'Driver Name',
                  controller: _nameCtr,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                ),
                SizedBox(height: 12.h),
                SosTextField(
                  label: 'Email Address',
                  controller: _emailCtr,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                SosTextField(
                  label: 'Phone Number',
                  controller: _phoneCtr,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) {
                      return 'Phone is required';
                    }
                    if ((v?.trim().length ?? 0) < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // ── License ────────────────────────────────────────────
                _SectionLabel(label: 'LICENSE DETAILS'),
                SizedBox(height: 10.h),
                SosTextField(
                  label: 'License Number (Optional)',
                  controller: _licenseCtr,
                  prefixIcon: Icons.badge_outlined,
                ),
                SizedBox(height: 12.h),
                // Date picker row
                SosCard(
                  onTap: _pickDate,
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _licenseExpiry != null
                            ? AppDesignTokens.success
                            : AppTheme.textSecondary(context),
                        size: 20.r,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _licenseExpiry != null
                            ? 'Expiry: ${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}'
                            : 'License Expiry Date (Optional)',
                        style: TextStyle(
                          color: _licenseExpiry != null
                              ? AppTheme.textPrimary(context)
                              : AppTheme.textSecondary(context),
                          fontSize: 14.sp,
                        ),
                      ),
                      if (_licenseExpiry != null) ...[
                        const Spacer(),
                        Icon(Icons.check_circle,
                            color: AppDesignTokens.success, size: 16.r),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // ── KYC documents ──────────────────────────────────────
                _SectionLabel(label: 'KYC DOCUMENTS'),
                SizedBox(height: 4.h),
                Text(
                  'Documents are optional — you can add them later from the driver profile.',
                  style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11.sp),
                ),
                SizedBox(height: 10.h),
                _docPickerTile(
                  label: 'License Document',
                  path: _licenseDocPath,
                  onTap: () => _pickDoc(true),
                ),
                SizedBox(height: 10.h),
                _docPickerTile(
                  label: 'ID Proof Document',
                  path: _idProofDocPath,
                  onTap: () => _pickDoc(false),
                ),
                SizedBox(height: 32.h),

                // ── Submit ─────────────────────────────────────────────
                BlocBuilder<AddDriverCubit, AddDriverState>(
                  builder: (_, state) {
                    final loading = state is AddDriverLoading;
                    return SosButton(
                      label: 'Create Driver',
                      loading: loading,
                      onPressed: loading ? null : _submit,
                    );
                  },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.accent(context),
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
