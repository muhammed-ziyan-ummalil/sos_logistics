import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sossss_logistics/Bloc/ActiveDelivery/active_delivery_cubit.dart';
import 'package:sossss_logistics/Screens/delivery/otp_entry_sheet.dart';

void main() {
  testWidgets('short OTP shows 6-digit validation snackbar', (tester) async {
    final cubit = ActiveDeliveryCubit();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            home: Scaffold(body: OtpEntrySheet(deliveryId: 1, isPickup: true)),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verify OTP'));
    await tester.pump(); // let the SnackBar appear
    expect(find.text('Enter the 6-digit OTP.'), findsOneWidget);
    await cubit.close();
  });
}
