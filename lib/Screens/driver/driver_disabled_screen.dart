import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

class DriverDisabledScreen extends StatelessWidget {
  const DriverDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: EmptyState(
                  icon: Icons.block_rounded,
                  title: 'Account Suspended',
                  subtitle:
                      'Your driver account has been disabled. Contact your fleet owner for help.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SosButton(
                  label: 'Logout',
                  variant: SosButtonVariant.outline,
                  onPressed: () => context.read<AuthCubit>().logout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
