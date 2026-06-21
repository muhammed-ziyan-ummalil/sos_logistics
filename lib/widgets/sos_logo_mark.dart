import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';

/// Branded mark: rounded-square primary tile with the shipping glyph,
/// optionally followed by the app name + tagline. Theme-aware.
class SosLogoMark extends StatelessWidget {
  final double size;
  final bool showTitle;

  const SosLogoMark({super.key, this.size = 72, this.showTitle = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = size * 0.244; // ~22/90 ratio from original splash
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: scheme.onPrimary,
            size: size * 0.489, // ~44/90 ratio from original splash
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: AppDesignTokens.spacingL),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDesignTokens.spacingXS),
          Text(
            'Delivery. Simplified.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
