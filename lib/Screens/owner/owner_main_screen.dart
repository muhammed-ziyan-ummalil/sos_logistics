import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface : AppLightColors.surface;
    final selectedColor = isDark ? AppColors.accent : AppLightColors.primary;
    final unselectedColor =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.background : AppLightColors.background,
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: bgColor,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
              fontSize: 11.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Manage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
