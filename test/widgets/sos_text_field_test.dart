import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/sos_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows label and accepts input', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(_wrap(SosTextField(label: 'Name', controller: ctrl)));
    expect(find.text('Name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ziy');
    expect(ctrl.text, 'Ziy');
  });

  testWidgets('shows validator error on invalid submit', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(_wrap(Form(
      key: key,
      child: SosTextField(label: 'Name', validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
    )));
    key.currentState!.validate();
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
  });
}
