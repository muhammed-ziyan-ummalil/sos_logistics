import 'package:flutter/material.dart';
import '../core/app_theme.dart';

Future<T?> showSosBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesignTokens.radiusCard)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: AppDesignTokens.spacingL,
        right: AppDesignTokens.spacingL,
        top: AppDesignTokens.spacingM,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDesignTokens.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: AppDesignTokens.spacingL),
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
          ],
          const SizedBox(height: AppDesignTokens.spacingL),
          child,
        ],
      ),
    ),
  );
}
