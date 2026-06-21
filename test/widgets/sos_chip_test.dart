import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_chip.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(_wrap(const SosChip(label: 'Active', tone: SosTone.success)));
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('every tone builds', (tester) async {
    for (final tone in SosTone.values) {
      await tester.pumpWidget(_wrap(SosChip(label: tone.name, tone: tone)));
      expect(find.text(tone.name), findsOneWidget);
    }
  });
}
