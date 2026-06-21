import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/loading_overlay.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows spinner when loading', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingOverlay(loading: true, child: Text('content'))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('no spinner when not loading', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingOverlay(loading: false, child: Text('content'))));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
