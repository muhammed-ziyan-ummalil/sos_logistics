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
  final _formKey  = GlobalKey<FormState>();
  final _nameCtr  = TextEditingController();
  final _emailCtr = TextEditingController();
  final _phoneCtr = TextEditingController();

  String? _licenseFrontPath;
  String? _licenseBackPath;

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _phoneCtr.dispose();
    super.dispose();
  }

  Future<void> _pickLicence(bool isFront) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        if (isFront) {
          _licenseFrontPath = file.path;
        } else {
          _licenseBackPath = file.path;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseFrontPath == null || _licenseBackPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both front and back of the driving licence.'),
        ),
      );
      return;
    }
    context.read<AddDriverCubit>().createDriver(
      name: _nameCtr.text.trim(),
      email: _emailCtr.text.trim(),
      phone: _phoneCtr.text.trim(),
      licenseFrontPath: _licenseFrontPath,
      licenseBackPath: _licenseBackPath,
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

                // ── Driving licence ────────────────────────────────────
                _SectionLabel(label: 'DRIVING LICENCE'),
                SizedBox(height: 4.h),
                Text(
                  'Upload clear photos of both sides of the driving licence.',
                  style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11.sp),
                ),
                SizedBox(height: 10.h),
                _docPickerTile(
                  label: 'Driving Licence - Front',
                  path: _licenseFrontPath,
                  onTap: () => _pickLicence(true),
                ),
                SizedBox(height: 10.h),
                _docPickerTile(
                  label: 'Driving Licence - Back',
                  path: _licenseBackPath,
                  onTap: () => _pickLicence(false),
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
