import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'sos_card.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatTile({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SosCard(
      padding: const EdgeInsets.all(AppDesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDesignTokens.iconSizeM, color: theme.colorScheme.primary),
          const SizedBox(height: AppDesignTokens.spacingS),
          Text(value, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
