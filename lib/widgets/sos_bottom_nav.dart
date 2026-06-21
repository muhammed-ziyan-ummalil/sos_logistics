import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SosNavItem {
  final IconData icon;
  final String label;
  const SosNavItem({required this.icon, required this.label});
}

class SosBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SosNavItem> items;

  const SosBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: scheme.primary,
        unselectedItemColor: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        items: items
            .map((i) => BottomNavigationBarItem(icon: Icon(i.icon), label: i.label))
            .toList(),
      ),
    );
  }
}
