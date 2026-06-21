import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders child', (tester) async {
    await tester.pumpWidget(_wrap(const SosCard(child: Text('hi'))));
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('onTap fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(SosCard(onTap: () => tapped = true, child: const Text('hi'))));
    await tester.tap(find.byType(SosCard));
    expect(tapped, true);
  });
}
