import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_logo_mark.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: Center(child: c)));

void main() {
  testWidgets('renders icon; title hidden by default, shown when showTitle', (tester) async {
    await tester.pumpWidget(_wrap(const SosLogoMark()));
    expect(find.byIcon(Icons.local_shipping_rounded), findsOneWidget);
    expect(find.text('SOSSSS Logistics'), findsNothing);

    await tester.pumpWidget(_wrap(const SosLogoMark(showTitle: true)));
    expect(find.text('SOSSSS Logistics'), findsOneWidget);
    expect(find.text('Delivery. Simplified.'), findsOneWidget);
  });
}
