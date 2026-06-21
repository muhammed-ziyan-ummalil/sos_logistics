import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_auth/sos_auth.dart';
import 'package:sossss_logistics/Screens/Auth/login_screen.dart';
import 'package:sossss_logistics/utility/v2_token_storage.dart';

void main() {
  testWidgets('empty submit shows validation errors', (tester) async {
    final auth = AuthCubit(
      authService: AuthService(baseUrl: 'https://api.sossss.net/'),
      tokenStorage: V2TokenStorage(),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    // tap Sign In without entering anything
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter email address'), findsOneWidget);
    expect(find.text('Enter password'), findsOneWidget);
    await auth.close();
  });
}
