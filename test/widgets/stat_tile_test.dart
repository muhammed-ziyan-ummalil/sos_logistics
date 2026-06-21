import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/stat_tile.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows label, value, icon', (tester) async {
    await tester.pumpWidget(_wrap(const StatTile(
      icon: Icons.local_shipping,
      label: 'Deliveries',
      value: '12',
    )));
    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
  });
}
