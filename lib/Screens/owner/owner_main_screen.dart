import 'package:flutter/material.dart';
import '../../core/dashboard_back_handler.dart';
import '../../widgets/widgets.dart';
import 'owner_home_screen.dart';
import 'owner_manage_screen.dart';
import 'account/owner_account_screen.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen>
    with DashboardBackHandler {
  int _tab = 0;

  static const List<Widget> _pages = [
    OwnerHomeScreen(),
    OwnerManageScreen(),
    OwnerAccountScreen(),
  ];

  @override
  int get selectedTabIndex => _tab;

  @override
  void onBackToFirstTab() => setState(() => _tab = 0);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => handleDashboardPop(didPop),
      child: Scaffold(
        body: IndexedStack(index: _tab, children: _pages),
        bottomNavigationBar: SosBottomNav(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            SosNavItem(icon: Icons.home_rounded, label: 'Home'),
            SosNavItem(icon: Icons.grid_view_rounded, label: 'Manage'),
            SosNavItem(icon: Icons.person_rounded, label: 'Account'),
          ],
        ),
      ),
    );
  }
}
