import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/widgets/wallet_balance_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows balance text with rupee symbol', (tester) async {
    await tester.pumpWidget(_wrap(const WalletBalanceCard(balanceLabel: '₹ 1,250.00')));
    expect(find.text('₹ 1,250.00'), findsOneWidget);
    expect(find.text('Wallet Balance'), findsOneWidget);
  });

  testWidgets('action button fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(WalletBalanceCard(
      balanceLabel: '₹ 0.00',
      actionLabel: 'Add Money',
      onAction: () => tapped = true,
    )));
    await tester.tap(find.text('Add Money'));
    expect(tapped, true);
  });
}
