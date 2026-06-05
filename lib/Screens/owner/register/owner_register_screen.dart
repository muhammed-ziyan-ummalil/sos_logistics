import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../../Bloc/OwnerOnboarding/owner_register_cubit.dart';
import '../../../Bloc/OwnerOnboarding/owner_register_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';

class OwnerRegisterScreen extends StatefulWidget {
  const OwnerRegisterScreen({super.key});

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtr        = TextEditingController();
  final _emailCtr       = TextEditingController();
  final _phoneCtr       = TextEditingController();
  final _passCtr        = TextEditingController();
  final _confPassCtr    = TextEditingController();
  final _bizNameCtr     = TextEditingController();
  final _vehicleRegCtr  = TextEditingController();
  final _capacityCtr    = TextEditingController();

  bool   _obscurePass  = true;
  bool   _obscureConf  = true;
  String _vehicleType  = 'bike';
  String? _kycDocPath;

  static const _vehicleTypes = ['bike', 'three_wheeler', 'mini_truck', 'truck', 'reefer'];

  @override
  void dispose() {
    _nameCtr.dispose(); _emailCtr.dispose(); _phoneCtr.dispose();
    _passCtr.dispose(); _confPassCtr.dispose(); _bizNameCtr.dispose();
    _vehicleRegCtr.dispose(); _capacityCtr.dispose();
    super.dispose();
  }

  Future<void> _pickKycDoc() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _kycDocPath = file.path);
  }

  bool _isSendingOtp = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSendingOtp = true);
    try {
      final authService  = context.read<AuthCubit>().authService;
      final tokenStorage = context.read<AuthCubit>().tokenStorage;
      final session = await authService.sendRegistrationOtps(
        email: _emailCtr.text.trim(),
        phone: _phoneCtr.text.trim(),
      );
      final pendingSession = PendingRegistrationSession(
        sessionId:  session.sessionId,
        email:      _emailCtr.text.trim(),
        phone:      _phoneCtr.text.trim(),
        expiresAt:  session.expiresAt,
        name:       _nameCtr.text.trim(),
        password:   _passCtr.text.trim(),
        capability: 'fleet_owner',
        extra: {
          'business_name':      _bizNameCtr.text.trim(),
          'vehicle_reg_number': _vehicleRegCtr.text.trim(),
          'vehicle_type':       _vehicleType,
          'capacity_kg':        double.tryParse(_capacityCtr.text.trim()) ?? 0.0,
          'kyc_doc_path':       _kycDocPath ?? '',
        },
      );
      await tokenStorage.savePendingRegistration(pendingSession);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => DualOtpCubit(authService: authService, tokenStorage: tokenStorage),
          child: DualOtpVerificationScreen(
            session: pendingSession,
            onBothVerified: (sessionId) => _completeRegistration(pendingSession, sessionId),
          ),
        ),
      ));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTPs. Please try again.')));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _completeRegistration(PendingRegistrationSession pending, String sessionId) {
    context.read<OwnerRegisterCubit>().register(
      name:             pending.name,
      email:            pending.email,
      phone:            pending.phone,
      password:         pending.password,
      sessionId:        sessionId,
      businessName:     pending.extra['business_name'] as String?,
      kycDocPath:       (pending.extra['kyc_doc_path'] as String?)?.isEmpty == true
                          ? null
                          : pending.extra['kyc_doc_path'] as String?,
      vehicleRegNumber: pending.extra['vehicle_reg_number'] as String? ?? '',
      vehicleType:      pending.extra['vehicle_type'] as String? ?? 'bike',
      capacityKg:       pending.extra['capacity_kg'] as double?,
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h, top: 20.h),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerRegisterCubit, OwnerRegisterState>(
      listener: (ctx, state) {
        if (state is OwnerRegisterSuccess) {
          showDialog(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Registration Submitted',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                'Your application has been submitted. You can log in after admin approval.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is OwnerRegisterError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Fleet Owner Registration'),
          backgroundColor: AppColors.surface,
          leading: BackButton(color: AppColors.textSecondary),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Details
                _sectionLabel('PERSONAL DETAILS'),
                TextFormField(
                  controller: _nameCtr,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _emailCtr,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _phoneCtr,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Phone is required';
                    if ((v?.trim().length ?? 0) < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _passCtr,
                  obscureText: _obscurePass,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Password is required';
                    if ((v?.trim().length ?? 0) < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _confPassCtr,
                  obscureText: _obscureConf,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConf = !_obscureConf),
                    ),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Confirm your password';
                    if (v?.trim() != _passCtr.text.trim()) return 'Passwords do not match';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _bizNameCtr,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Business Name (Optional)',
                    prefixIcon: Icon(Icons.business_outlined, color: AppColors.textSecondary),
                  ),
                ),

                // KYC
                _sectionLabel('KYC DOCUMENT'),
                GestureDetector(
                  onTap: _pickKycDoc,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: _kycDocPath != null
                        ? Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(File(_kycDocPath!), height: 60.r, width: 80.r, fit: BoxFit.cover),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(child: Text('KYC document selected',
                                style: TextStyle(color: AppColors.success, fontSize: 13.sp))),
                            Icon(Icons.check_circle, color: AppColors.success, size: 20.r),
                          ])
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.upload_file_rounded, color: AppColors.textSecondary, size: 24.r),
                            SizedBox(width: 8.w),
                            Text('Upload KYC Document',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
                          ]),
                  ),
                ),

                // Vehicle
                _sectionLabel('FIRST VEHICLE (REQUIRED)'),
                TextFormField(
                  controller: _vehicleRegCtr,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    prefixIcon: Icon(Icons.directions_car_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Vehicle registration number required' : null,
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  dropdownColor: AppColors.card,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(Icons.local_shipping_outlined, color: AppColors.textSecondary),
                  ),
                  items: _vehicleTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.replaceAll('_', ' ').toUpperCase()),
                  )).toList(),
                  onChanged: (v) => setState(() => _vehicleType = v ?? 'bike'),
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _capacityCtr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'Capacity (kg) — Optional',
                    prefixIcon: Icon(Icons.scale_outlined, color: AppColors.textSecondary),
                  ),
                ),
                SizedBox(height: 32.h),

                BlocBuilder<OwnerRegisterCubit, OwnerRegisterState>(
                  builder: (_, state) {
                    final loading = state is OwnerRegisterLoading || _isSendingOtp;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? SizedBox(
                                height: 20.r, width: 20.r,
                                child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Submit Registration'),
                      ),
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
