import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'sos_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDesignTokens.iconSizeL, color: theme.colorScheme.outline),
            const SizedBox(height: AppDesignTokens.spacingM),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppDesignTokens.spacingS),
              Text(subtitle!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDesignTokens.spacingL),
              SosButton(label: actionLabel!, onPressed: onAction, fullWidth: false),
            ],
          ],
        ),
      ),
    );
  }
}
