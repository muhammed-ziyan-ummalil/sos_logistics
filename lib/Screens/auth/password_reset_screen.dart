import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../Bloc/Auth/password_reset_cubit.dart';
import '../../Bloc/Auth/password_reset_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../widgets/widgets.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _newPassCtr  = TextEditingController();
  final _confPassCtr = TextEditingController();
  bool _obscureNew   = true;
  bool _obscureConf  = true;

  @override
  void dispose() {
    _newPassCtr.dispose();
    _confPassCtr.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PasswordResetCubit>().resetPassword(
      newPassword:     _newPassCtr.text.trim(),
      confirmPassword: _confPassCtr.text.trim(),
    );
  }

  void _navigateAfterReset(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      // Fallback: auth state not ready — send to role selection.
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (_) => false);
      return;
    }

    final caps      = authState.person.capabilities;
    final hasOwner  = caps.any((c) => c.capability == Capability.fleetOwner);
    final hasDriver = caps.any((c) => c.capability == Capability.driver);

    if (hasOwner && hasDriver) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (_) => false);
      return;
    }

    if (hasOwner) {
      final ownerCap = caps.where((c) => c.capability == Capability.fleetOwner).firstOrNull;
      if (ownerCap == null) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (_) => false);
        return;
      }
      final route = ownerCap.status == 'active' ? AppRoutes.v2OwnerDashboard : AppRoutes.v2OwnerPending;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      return;
    }

    if (hasDriver) {
      final driverCap = caps.where((c) => c.capability == Capability.driver).firstOrNull;
      if (driverCap == null) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (_) => false);
        return;
      }
      final route = driverCap.status == 'active' ? AppRoutes.home : AppRoutes.v2DriverDisabled;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      return;
    }

    // No relevant caps.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    return BlocListener<PasswordResetCubit, PasswordResetState>(
      listener: (ctx, state) {
        if (state is PasswordResetSuccess) {
          _navigateAfterReset(ctx);
        } else if (state is PasswordResetError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: scheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingXL,
              vertical: AppDesignTokens.spacingXL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDesignTokens.spacingXXL),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppDesignTokens.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppDesignTokens.warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXL),
                  Text(
                    'Reset Your Password',
                    style: tt.headlineMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingS),
                  Text(
                    'This is required before you can continue. Your account was set up with a temporary password.',
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXXL),
                  SosTextField(
                    label: 'New Password',
                    controller: _newPassCtr,
                    obscureText: _obscureNew,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter new password';
                      if (v.trim().length < 6) return 'At least 6 characters required';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spacingL),
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
                      if (v == null || v.trim().isEmpty) return 'Confirm your password';
                      if (v.trim() != _newPassCtr.text.trim()) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXXL),
                  BlocBuilder<PasswordResetCubit, PasswordResetState>(
                    builder: (_, state) {
                      return SosButton(
                        label: 'Update Password',
                        loading: state is PasswordResetLoading,
                        onPressed: state is PasswordResetLoading ? null : _submit,
                      );
                    },
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
