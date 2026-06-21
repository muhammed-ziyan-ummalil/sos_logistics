import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/error_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows message and retry fires', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(ErrorState(
      message: 'Network failed',
      onRetry: () => retried = true,
    )));
    expect(find.text('Network failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, true);
  });

  testWidgets('no retry button when onRetry null', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'x')));
    expect(find.text('Retry'), findsNothing);
  });
}
