import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum SosTone { neutral, success, warning, error, info }

class SosChip extends StatelessWidget {
  final String label;
  final SosTone tone;
  final IconData? icon;

  const SosChip({super.key, required this.label, this.tone = SosTone.neutral, this.icon});

  Color _base(BuildContext context) {
    switch (tone) {
      case SosTone.success:
        return AppDesignTokens.success;
      case SosTone.warning:
        return AppDesignTokens.warning;
      case SosTone.error:
        return Theme.of(context).colorScheme.error;
      case SosTone.info:
        return AppDesignTokens.lightAccent;
      case SosTone.neutral:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _base(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: base), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: base)),
        ],
      ),
    );
  }
}
