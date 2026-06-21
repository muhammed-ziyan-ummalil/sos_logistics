import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_bottom_nav.dart';

void main() {
  testWidgets('renders items and reports tap index', (tester) async {
    var picked = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: SosBottomNav(
          currentIndex: 0,
          onTap: (i) => picked = i,
          items: const [
            SosNavItem(icon: Icons.home, label: 'Home'),
            SosNavItem(icon: Icons.history, label: 'History'),
            SosNavItem(icon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    ));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('History'));
    expect(picked, 1);
  });
}
