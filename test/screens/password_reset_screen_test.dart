import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_auth/sos_auth.dart';
import 'package:sossss_logistics/Bloc/Auth/password_reset_cubit.dart';
import 'package:sossss_logistics/Screens/auth/password_reset_screen.dart';
import 'package:sossss_logistics/utility/v2_token_storage.dart';

void main() {
  testWidgets('mismatched passwords show validation error', (tester) async {
    final reset = PasswordResetCubit();
    final auth = AuthCubit(
      authService: AuthService(baseUrl: 'https://api.sossss.net/'),
      tokenStorage: V2TokenStorage(),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: reset),
          BlocProvider.value(value: auth),
        ],
        child: const MaterialApp(home: PasswordResetScreen()),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'secret123');
    await tester.enterText(fields.at(1), 'different');
    await tester.tap(find.text('Update Password'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await reset.close();
    await auth.close();
  });
}
