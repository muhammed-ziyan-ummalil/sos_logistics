import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../../Bloc/OwnerOnboarding/owner_register_cubit.dart';
import '../../../Bloc/OwnerOnboarding/owner_register_state.dart';
import '../../../core/app_constants.dart';
import '../../../utility/pincode_autofill_field.dart';
import '../../../utility/form_validators.dart';
import '../../../widgets/widgets.dart';
import '../../../services/firebase_notification_service.dart';
import 'service_area_picker_screen.dart';

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

  bool   _obscurePass  = true;
  bool   _obscureConf  = true;
  String? _selectedGender;

  static const _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  final _addressLineCtrl = TextEditingController();
  final _areaCtrl        = TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _stateCtrl       = TextEditingController();
  final _pincodeCtrl     = TextEditingController();

  // Service area (region targeting): owner taps a map to mark their delivery
  // centre and sets how far out they serve (radius in km).
  double? _serviceLat;
  double? _serviceLng;
  double? _serviceRadiusKm;

  @override
  void dispose() {
    _nameCtr.dispose(); _emailCtr.dispose(); _phoneCtr.dispose();
    _passCtr.dispose(); _confPassCtr.dispose();
    _addressLineCtrl.dispose(); _areaCtrl.dispose(); _cityCtrl.dispose();
    _stateCtrl.dispose(); _pincodeCtrl.dispose();
    super.dispose();
  }

  bool _isSendingOtp = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSendingOtp = true);
    try {
      final authService  = context.read<AuthCubit>().authService;
      final tokenStorage = context.read<AuthCubit>().tokenStorage;

      // Existing SOS account (any role) → don't re-register or re-ask details.
      // Sign in with the existing password and the Owner role is added from
      // the details on file (no OTP, no new password).
      try {
        final existingCaps = await authService.discover(_emailCtr.text.trim());
        if (existingCaps.isNotEmpty) {
          if (!mounted) return;
          setState(() => _isSendingOtp = false);
          final signIn = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Account already exists'),
              content: const Text(
                  'This email already has an SOS account. Sign in with your '
                  'existing password to add the Fleet Owner role — your '
                  'details are reused automatically, nothing to re-enter.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Use another email')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sign In')),
              ],
            ),
          );
          if (signIn == true && mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login,
                arguments: UserRole.owner);
          }
          return;
        }
      } on AuthException {
        // discover unavailable — fall through to the normal OTP flow;
        // the backend still rejects duplicate emails at register.
      }

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
          'gender':             (_selectedGender ?? 'male').toLowerCase(),
          'address_line':       _addressLineCtrl.text.trim(),
          'area':               _areaCtrl.text.trim(),
          'city':               _cityCtrl.text.trim(),
          'state':              _stateCtrl.text.trim(),
          'pincode':            _pincodeCtrl.text.trim(),
          if (_serviceLat != null) 'service_lat': _serviceLat.toString(),
          if (_serviceLng != null) 'service_lng': _serviceLng.toString(),
          if (_serviceRadiusKm != null) 'service_radius_km': _serviceRadiusKm.toString(),
          // Test-mode OTP prefill (no live SMS yet).
          if (session.devEmailOtp != null) 'dev_email_otp': session.devEmailOtp,
          if (session.devSmsOtp != null)   'dev_sms_otp':   session.devSmsOtp,
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
      gender:           pending.extra['gender'] as String?,
      addressLine:      pending.extra['address_line'] as String?,
      area:             pending.extra['area'] as String?,
      city:             pending.extra['city'] as String?,
      state:            pending.extra['state'] as String?,
      pincode:          pending.extra['pincode'] as String?,
      serviceLat:       pending.extra['service_lat'] as String?,
      serviceLng:       pending.extra['service_lng'] as String?,
      serviceRadiusKm:  pending.extra['service_radius_km'] as String?,
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

  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 20.h),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<OwnerRegisterCubit, OwnerRegisterState>(
          listener: (ctx, state) {
            if (state is OwnerRegisterSuccess) {
              // Auto-login so the owner lands on the locked pending dashboard
              // (unlocks once an admin approves), instead of bouncing to login.
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Account created. Awaiting admin approval.')));
              ctx.read<AuthCubit>().login(
                    _emailCtr.text.trim(),
                    _passCtr.text.trim(),
                  );
            } else if (state is OwnerRegisterError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
              );
            }
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated) {
              // Register the FCM token so the approval push reaches this owner.
              FirebaseNotificationService.syncTokenAfterLogin();
              final ownerCap = state.person.capabilities
                  .where((c) => c.capability == Capability.fleetOwner)
                  .firstOrNull;
              Navigator.pushReplacementNamed(
                ctx,
                (ownerCap != null && ownerCap.status == 'active')
                    ? AppRoutes.v2OwnerDashboard
                    : AppRoutes.v2OwnerPending,
              );
            } else if (state is AuthError) {
              // Registered but auto-login failed; let them log in manually.
              Navigator.pushReplacementNamed(ctx, AppRoutes.login);
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: const SosAppBar(title: 'Fleet Owner Registration'),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Details
                _sectionLabel('PERSONAL DETAILS'),
                SosTextField(
                  label: 'Full Name',
                  controller: _nameCtr,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
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
                    if (v?.trim().isEmpty ?? true) return 'Phone is required';
                    if ((v?.trim().length ?? 0) < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  dropdownColor: scheme.surface,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Gender (Optional)',
                    prefixIcon: Icon(Icons.wc_outlined, color: scheme.onSurfaceVariant),
                  ),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                SizedBox(height: 12.h),
                SosTextField(
                  label: 'Password',
                  controller: _passCtr,
                  obscureText: _obscurePass,
                  prefixIcon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Password is required';
                    if ((v?.trim().length ?? 0) < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                SosTextField(
                  label: 'Confirm Password',
                  controller: _confPassCtr,
                  obscureText: _obscureConf,
                  prefixIcon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscureConf = !_obscureConf),
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Confirm your password';
                    if (v?.trim() != _passCtr.text.trim()) return 'Passwords do not match';
                    return null;
                  },
                ),

                // Address
                _sectionLabel('ADDRESS'),
                PincodeAutofillField(
                  controller: _pincodeCtrl,
                  cityController: _cityCtrl,
                  stateController: _stateCtrl,
                  areaController: _areaCtrl,
                  validator: FormValidators.pincode,
                ),
                SizedBox(height: 12.h),
                SosTextField(
                  label: 'Flat / Building / Street',
                  controller: _addressLineCtrl,
                  prefixIcon: Icons.home_outlined,
                ),
                SizedBox(height: 12.h),
                SosTextField(
                  label: 'Area / Locality',
                  controller: _areaCtrl,
                  prefixIcon: Icons.place_outlined,
                ),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(child: SosTextField(
                    label: 'City',
                    controller: _cityCtrl,
                    prefixIcon: Icons.location_city_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'City required' : null,
                  )),
                  SizedBox(width: 12.w),
                  Expanded(child: SosTextField(
                    label: 'State',
                    controller: _stateCtrl,
                    prefixIcon: Icons.map_outlined,
                  )),
                ]),

                // Service Area (region targeting for delivery requests)
                _sectionLabel('SERVICE AREA'),
                Text(
                  'Mark the centre of the area you deliver in so we only send you nearby '
                  'delivery requests. Optional, but recommended.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 12.h),
                SosCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.my_location_outlined,
                      color: (_serviceLat != null) ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    title: Text(
                      (_serviceLat != null && _serviceLng != null)
                          ? (_serviceRadiusKm != null
                              ? 'Service area set | ${_serviceRadiusKm!.round()} km radius'
                              : 'Service area set')
                          : 'Pick your service area on map',
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: (_serviceLat != null && _serviceLng != null)
                        ? Text(
                            '${_serviceLat!.toStringAsFixed(5)}, ${_serviceLng!.toStringAsFixed(5)}',
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickServiceArea,
                  ),
                ),

                SizedBox(height: 32.h),

                BlocBuilder<OwnerRegisterCubit, OwnerRegisterState>(
                  builder: (_, state) {
                    final loading = state is OwnerRegisterLoading || _isSendingOtp;
                    return SosButton(
                      label: 'Create Account',
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
