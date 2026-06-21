import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_app_bar.dart';

void main() {
  testWidgets('shows title and actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: SosAppBar(title: 'Deliveries', actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})]),
        body: const SizedBox(),
      ),
    ));
    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('implements PreferredSizeWidget', (tester) async {
    const bar = SosAppBar(title: 'x');
    expect(bar.preferredSize.height, kToolbarHeight);
  });
}
