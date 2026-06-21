import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import 'owner_home_screen.dart';
import 'owner_manage_screen.dart';
import 'account/owner_account_screen.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {
  int _tab = 0;

  static const List<Widget> _pages = [
    OwnerHomeScreen(),
    OwnerManageScreen(),
    OwnerAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
