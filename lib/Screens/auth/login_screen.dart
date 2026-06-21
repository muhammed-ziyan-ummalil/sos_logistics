import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../services/firebase_notification_service.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtr  = TextEditingController();
  final _passCtr   = TextEditingController();
  bool  _obscure   = true;
  late  String _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _role = (ModalRoute.of(context)?.settings.arguments as String?) ?? UserRole.driver;
  }

  @override
  void dispose() {
    _emailCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Pass FCM token at login so the backend receives it atomically with the
    // login call. A post-login syncTokenAfterLogin() call also fires as a
    // belt-and-suspenders guard (handles token refresh after login).
    final email = _emailCtr.text.trim();
    final password = _passCtr.text.trim();
    FirebaseMessaging.instance.getToken().then((fcmToken) {
      if (!mounted) return;
      context.read<AuthCubit>().login(
        email,
        password,
        firebaseToken: fcmToken,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _role == UserRole.owner;
    final scheme  = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthMustResetPassword) {
              Navigator.pushReplacementNamed(ctx, AppRoutes.v2PasswordReset);
              return;
            }
            if (state is AuthAuthenticated) {
              // Sync FCM token now that we have a valid JWT.
              FirebaseNotificationService.syncTokenAfterLogin();
              final caps = state.person.capabilities;

              // Capability-driven routing — ignore the UI _role selection for
              // determining the destination; use it only for the "not found" error.
              if (_role == UserRole.owner) {
                final ownerCap = caps
                    .where((c) => c.capability == Capability.fleetOwner)
                    .firstOrNull;
                if (ownerCap != null) {
                  Navigator.pushReplacementNamed(
                    ctx,
                    ownerCap.status == 'active'
                        ? AppRoutes.v2OwnerDashboard
                        : AppRoutes.v2OwnerPending,
                  );
                } else {
                  Navigator.pushReplacementNamed(ctx, AppRoutes.v2NotAnOwner);
                }
              } else {
                final driverCap = caps
                    .where((c) => c.capability == Capability.driver)
                    .firstOrNull;
                if (driverCap != null) {
                  Navigator.pushReplacementNamed(
                    ctx,
                    driverCap.status == 'active'
                        ? AppRoutes.home
                        : AppRoutes.v2DriverDisabled,
                  );
                } else {
                  Navigator.pushReplacementNamed(ctx, AppRoutes.v2NotADriver);
                }
              }
            } else if (state is AuthError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: scheme.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: const SosAppBar(title: ''),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingXL,
              vertical: AppDesignTokens.spacingL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDesignTokens.spacingL),
                  const SosLogoMark(size: 64),
                  const SizedBox(height: AppDesignTokens.spacingXL),
                  Text(
                    'Welcome back',
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXS),
                  Text(
                    isOwner ? 'Fleet Owner Login' : 'Driver Login',
                    style: tt.headlineMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingS),
                  Text(
                    isOwner
                        ? 'Sign in to manage your fleet and deliveries.'
                        : 'Sign in to start accepting delivery jobs.',
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXXL),
                  SosTextField(
                    label: 'Email',
                    controller: _emailCtr,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter email address';
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spacingL),
                  SosTextField(
                    label: 'Password',
                    controller: _passCtr,
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter password' : null,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXXL),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (_, state) {
                      return SosButton(
                        label: 'Sign In',
                        loading: state is AuthLoading,
                        onPressed: state is AuthLoading ? null : _submit,
                      );
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXL),
                  if (isOwner)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.v2OwnerRegister),
                            child: Text(
                              'Create account',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        'Contact your fleet owner to get an account.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
