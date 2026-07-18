import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sos_auth/sos_auth.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

/// Shown after login when the account has no fleet_owner capability.
///
/// The person is already authenticated, so becoming an owner is a one-tap
/// role add: add-capability creates the pending capability AND a bare
/// vehicle_owners row backfilled from the details on file (no re-entry of
/// name/phone/address, no OTP). Admin approval then unlocks the dashboard;
/// service area, vehicles and KYC are completed in-app after approval.
class NotAnOwnerScreen extends StatefulWidget {
  const NotAnOwnerScreen({super.key});

  @override
  State<NotAnOwnerScreen> createState() => _NotAnOwnerScreenState();
}

class _NotAnOwnerScreenState extends State<NotAnOwnerScreen> {
  bool _submitting = false;

  Future<void> _becomeOwner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Become a Fleet Owner?'),
        content: const Text(
            'This submits an Owner request for admin review using your '
            'existing account details — nothing to re-enter. After approval '
            'you can set your service area, vehicles and KYC here.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send request')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final result =
        await context.read<AuthCubit>().addCapability(Capability.fleetOwner);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.v2OwnerPending);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Could not send the owner request.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SosAppBar(title: ''),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: EmptyState(
                icon: Icons.warehouse_rounded,
                title: 'Not a Fleet Owner',
                subtitle:
                    'Your account does not have the Fleet Owner role yet. '
                    'Request it with one tap — your existing details are '
                    'reused and an admin will review it.',
                actionLabel:
                    _submitting ? 'Sending request…' : 'Become a Fleet Owner',
                onAction: _submitting ? null : _becomeOwner,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
