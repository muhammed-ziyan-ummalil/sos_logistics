import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'sos_button.dart';

class WalletBalanceCard extends StatelessWidget {
  final String balanceLabel;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WalletBalanceCard({
    super.key,
    required this.balanceLabel,
    this.title = 'Wallet Balance',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignTokens.spacingXL),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        boxShadow: AppDesignTokens.walletGlow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppDesignTokens.spacingS),
          Text(balanceLabel, style: TextStyle(color: scheme.onPrimary, fontSize: 30, fontWeight: FontWeight.w700)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDesignTokens.spacingL),
            SosButton(
              label: actionLabel!,
              variant: SosButtonVariant.outline,
              onPressed: onAction,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}
