import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/skeleton_box.dart';

void main() {
  testWidgets('builds with given size', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SkeletonBox(width: 100, height: 20)),
    ));
    expect(find.byType(SkeletonBox), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
