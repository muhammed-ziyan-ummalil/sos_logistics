import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

class OwnerPendingScreen extends StatelessWidget {
  const OwnerPendingScreen({super.key});

  bool _ownerActive(AuthPerson person) {
    final cap = person.capabilities
        .where((c) => c.capability == Capability.fleetOwner)
        .firstOrNull;
    return cap != null && cap.status == 'active';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(ctx, AppRoutes.roleSelection);
        } else if (state is AuthAuthenticated) {
          if (_ownerActive(state.person)) {
            // Approved - unlock the dashboard.
            Navigator.pushReplacementNamed(ctx, AppRoutes.v2OwnerDashboard);
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Still awaiting admin approval.')));
          }
        }
      },
      builder: (ctx, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => ctx.read<AuthCubit>().init(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(ctx).size.height * 0.26),
                  const EmptyState(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Approval Pending',
                    subtitle:
                        'Your fleet owner account is awaiting admin approval. You will be notified once approved.',
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SosButton(
                      label: 'Refresh',
                      loading: loading,
                      onPressed:
                          loading ? null : () => ctx.read<AuthCubit>().init(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(24),
            child: SosButton(
              label: 'Logout',
              variant: SosButtonVariant.outline,
              onPressed: () => ctx.read<AuthCubit>().logout(),
            ),
          ),
        );
      },
    );
  }
}
