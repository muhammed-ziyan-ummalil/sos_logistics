import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';

class NotADriverScreen extends StatelessWidget {
  const NotADriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SosAppBar(title: ''),
      body: SafeArea(
        child: EmptyState(
          icon: Icons.no_accounts_rounded,
          title: 'Not a Driver',
          subtitle:
              'You are not assigned as a driver. Contact your fleet owner to get access.',
          actionLabel: 'Go Back',
          onAction: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
