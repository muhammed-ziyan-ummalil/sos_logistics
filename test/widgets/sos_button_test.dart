import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(SosButton(label: 'Go', onPressed: () => tapped = true)));
    expect(find.text('Go'), findsOneWidget);
    await tester.tap(find.byType(SosButton));
    expect(tapped, true);
  });

  testWidgets('loading shows spinner, hides label, blocks tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(SosButton(label: 'Go', loading: true, onPressed: () => tapped = true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Go'), findsNothing);
    await tester.tap(find.byType(SosButton));
    expect(tapped, false);
  });

  testWidgets('outline variant uses OutlinedButton', (tester) async {
    await tester.pumpWidget(_wrap(SosButton(label: 'X', variant: SosButtonVariant.outline, onPressed: () {})));
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
