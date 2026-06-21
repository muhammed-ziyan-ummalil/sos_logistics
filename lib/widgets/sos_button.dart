import 'package:flutter/material.dart';

enum SosButtonVariant { primary, outline, danger }

class SosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SosButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final IconData? icon;

  const SosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SosButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = loading || onPressed == null;

    Widget child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: variant == SosButtonVariant.outline ? scheme.primary : scheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final VoidCallback? handler = disabled ? null : onPressed;
    Widget button;
    switch (variant) {
      case SosButtonVariant.primary:
        button = ElevatedButton(onPressed: handler, child: child);
        break;
      case SosButtonVariant.outline:
        button = OutlinedButton(onPressed: handler, child: child);
        break;
      case SosButtonVariant.danger:
        button = ElevatedButton(
          onPressed: handler,
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
