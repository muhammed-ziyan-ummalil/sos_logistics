import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title, subtitle, icon', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'No deliveries',
      subtitle: 'New requests appear here',
    )));
    expect(find.text('No deliveries'), findsOneWidget);
    expect(find.text('New requests appear here'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
  });

  testWidgets('optional action fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(EmptyState(
      icon: Icons.inbox,
      title: 'Empty',
      actionLabel: 'Refresh',
      onAction: () => tapped = true,
    )));
    await tester.tap(find.text('Refresh'));
    expect(tapped, true);
  });
}
