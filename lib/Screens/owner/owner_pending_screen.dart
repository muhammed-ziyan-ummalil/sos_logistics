import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

class OwnerPendingScreen extends StatelessWidget {
  const OwnerPendingScreen({super.key});

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
              const Expanded(
                child: EmptyState(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Approval Pending',
                  subtitle:
                      'Your fleet owner account is awaiting admin approval. You will be notified once approved.',
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
