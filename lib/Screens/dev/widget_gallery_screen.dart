import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/theme_controller.dart';
import '../../widgets/widgets.dart';

// Dev-only gallery to eyeball every shared widget in light + dark.
// Kept until the redesign is complete, then deleted.
class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SosAppBar(
        title: 'Widget Gallery',
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              themeController.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDesignTokens.spacingL),
        children: [
          const WalletBalanceCard(balanceLabel: '₹ 1,250.00', actionLabel: 'Add Money', onAction: _noop),
          const SizedBox(height: 16),
          Row(children: const [
            Expanded(child: StatTile(icon: Icons.local_shipping, label: 'Deliveries', value: '12')),
            SizedBox(width: 12),
            Expanded(child: StatTile(icon: Icons.attach_money, label: 'Earnings', value: '₹ 8.2k')),
          ]),
          const SizedBox(height: 16),
          SosButton(label: 'Primary', onPressed: () {}),
          const SizedBox(height: 8),
          SosButton(label: 'Outline', variant: SosButtonVariant.outline, onPressed: () {}),
          const SizedBox(height: 8),
          SosButton(label: 'Danger', variant: SosButtonVariant.danger, onPressed: () {}),
          const SizedBox(height: 8),
          const SosButton(label: 'Loading', onPressed: null, loading: true),
          const SizedBox(height: 16),
          const SosCard(child: Text('A SosCard with body content.')),
          const SizedBox(height: 16),
          const SosTextField(label: 'Driver name', hint: 'Enter name'),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            SosChip(label: 'Active', tone: SosTone.success),
            SosChip(label: 'Pending', tone: SosTone.warning),
            SosChip(label: 'Failed', tone: SosTone.error),
            SosChip(label: 'Info', tone: SosTone.info),
            SosChip(label: 'Neutral', tone: SosTone.neutral),
          ]),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 18),
          const SizedBox(height: 8),
          const SkeletonBox(width: 160, height: 18),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No deliveries',
              subtitle: 'New requests will show here',
              actionLabel: 'Refresh',
              onAction: () {},
            ),
          ),
          SizedBox(
            height: 200,
            child: ErrorState(message: 'Something went wrong', onRetry: () {}),
          ),
          SosButton(
            label: 'Open bottom sheet',
            onPressed: () => showSosBottomSheet(
              context: context,
              title: 'Sample sheet',
              child: const Text('Bottom sheet body content.'),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
