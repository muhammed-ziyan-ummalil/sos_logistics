import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

class NotAnOwnerScreen extends StatelessWidget {
  const NotAnOwnerScreen({super.key});

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
                    'You are not registered as a Fleet Owner. Register to manage your fleet.',
                actionLabel: 'Register as Fleet Owner',
                onAction: () => Navigator.pushReplacementNamed(
                    context, AppRoutes.v2OwnerRegister),
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
