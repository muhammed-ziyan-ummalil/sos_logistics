import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'sos_button.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: AppDesignTokens.iconSizeL, color: theme.colorScheme.error),
            const SizedBox(height: AppDesignTokens.spacingM),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppDesignTokens.spacingL),
              SosButton(label: 'Retry', variant: SosButtonVariant.outline, onPressed: onRetry, fullWidth: false),
            ],
          ],
        ),
      ),
    );
  }
}
