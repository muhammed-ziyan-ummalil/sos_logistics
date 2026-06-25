import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../Bloc/OwnerOnboarding/owner_register_cubit.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _checkPendingRegistration();
    });
  }

  Future<void> _checkPendingRegistration() async {
    final tokenStorage = context.read<AuthCubit>().tokenStorage;
    final pending      = await tokenStorage.getPendingRegistration();

    if (pending != null && !pending.isExpired) {
      if (!mounted) return;
      final authService = context.read<AuthCubit>().authService;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => DualOtpCubit(
                  authService: authService, tokenStorage: tokenStorage),
            ),
            BlocProvider.value(value: ctx.read<OwnerRegisterCubit>()),
          ],
          child: DualOtpVerificationScreen(
            session: pending,
            onBothVerified: (sessionId) {
              ctx.read<OwnerRegisterCubit>().register(
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
              );
            },
          ),
        ),
      ));
      return;
    }

    if (pending != null) await tokenStorage.clearPendingRegistration();
    if (mounted) context.read<AuthCubit>().init();
  }

  void _routeFromAuth(BuildContext context, AuthAuthenticated state) {
    final caps = state.person.capabilities;

    final hasOwner  = caps.any((c) => c.capability == Capability.fleetOwner);
    final hasDriver = caps.any((c) => c.capability == Capability.driver);

    if (hasOwner && hasDriver) {
      // Both roles — let user pick.
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      return;
    }

    if (hasOwner) {
      final ownerCap = caps.where((c) => c.capability == Capability.fleetOwner).firstOrNull;
      if (ownerCap == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        ownerCap.status == 'active'
            ? AppRoutes.v2OwnerDashboard
            : AppRoutes.v2OwnerPending,
      );
      return;
    }

    if (hasDriver) {
      final driverCap = caps.where((c) => c.capability == Capability.driver).firstOrNull;
      if (driverCap == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        driverCap.status == 'active'
            ? AppRoutes.home
            : AppRoutes.v2DriverDisabled,
      );
      return;
    }

    // Authenticated but no logistics capability — send to role selection / login.
    Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthMustResetPassword) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.v2PasswordReset);
        } else if (state is AuthAuthenticated) {
          _routeFromAuth(ctx, state);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SosLogoMark(size: 90, showTitle: true),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
