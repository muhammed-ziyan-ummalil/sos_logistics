import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_bottom_sheet.dart';

void main() {
  testWidgets('showSosBottomSheet displays content', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSosBottomSheet(
              context: context,
              title: 'OTP',
              child: const Text('enter code'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('OTP'), findsOneWidget);
    expect(find.text('enter code'), findsOneWidget);
  });
}
