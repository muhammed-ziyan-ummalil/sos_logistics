import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sos_auth/sos_auth.dart';

import 'Bloc/ActiveDelivery/active_delivery_cubit.dart';
import 'Bloc/Auth/password_reset_cubit.dart';
import 'Bloc/Availability/availability_cubit.dart';
import 'Bloc/DeliveryFeed/delivery_feed_cubit.dart';
import 'Bloc/Fleet/driver_detail_cubit.dart';
import 'Bloc/Fleet/fleet_dashboard_cubit.dart';
import 'Bloc/History/history_cubit.dart';
import 'Bloc/MyQuotes/my_quotes_cubit.dart';
import 'Bloc/OwnerBankDetails/owner_bank_details_cubit.dart';
import 'Bloc/OwnerDrivers/add_driver_cubit.dart';
import 'Bloc/OwnerOnboarding/owner_register_cubit.dart';
import 'Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import 'Bloc/OwnerWallet/owner_wallet_cubit.dart';
import 'Bloc/QuoteSubmit/quote_submit_cubit.dart';
import 'Screens/auth/login_screen.dart';
import 'Screens/auth/not_a_driver_screen.dart';
import 'Screens/auth/not_an_owner_screen.dart';
import 'Screens/auth/password_reset_screen.dart';
import 'Screens/auth/role_selection_screen.dart';
import 'Screens/auth/splash_screen.dart';
import 'Screens/dev/widget_gallery_screen.dart';
import 'Screens/driver/driver_disabled_screen.dart';
import 'Screens/home/home_screen.dart';
import 'Screens/owner/drivers/add_driver_screen.dart';
import 'Screens/owner/drivers/driver_detail_screen.dart';
import 'Screens/owner/drivers/drivers_list_screen.dart';
import 'Screens/owner/owner_main_screen.dart';
import 'Screens/owner/owner_pending_screen.dart';
import 'Screens/owner/register/owner_register_screen.dart';
import 'Screens/owner/vehicles/owner_vehicles_screen.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'firebase_options.dart';
import 'services/firebase_notification_service.dart';
import 'utility/v2_token_storage.dart';

// ─── FCM background handler ───────────────────────────────────────────────────
// Must be a top-level function annotated with @pragma so the Dart VM keeps it
// alive when the app is terminated. Registered in main() before runApp.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-initialize Firebase in the background isolate.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Show a local notification only for data-only messages (no notification
  // block); the system tray handles notification-type messages automatically.
  if (message.notification == null) {
    await FirebaseNotificationService.showFromBackground(message);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await themeController.loadSavedTheme();

  // ── Firebase init ───────────────────────────────────────────────────────────
  // Guarded so the app still runs before google-services.json is added (i.e.
  // before `flutterfire configure` is run). When the stub REPLACE_ME values are
  // present, Firebase.initializeApp() will throw; we catch it, log, and skip
  // FCM init so the rest of the app is unaffected.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseNotificationService.init();
  } catch (e) {
    // ignore: avoid_print
    print('[FCM] Firebase init skipped — run flutterfire configure first: $e');
  }

  runApp(const SOSLogisticsApp());
}

class SOSLogisticsApp extends StatelessWidget {
  const SOSLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AvailabilityCubit()),
        BlocProvider(create: (_) => ActiveDeliveryCubit()),
        BlocProvider(create: (_) => HistoryCubit()),
        // V2 cubits — shared sos_auth AuthCubit
        BlocProvider(
          create: (_) => AuthCubit(
            authService: AuthService(baseUrl: 'https://api.sossss.net/api/'),
            tokenStorage: V2TokenStorage(),
          ),
        ),
        BlocProvider(create: (_) => PasswordResetCubit()),
        BlocProvider(create: (_) => OwnerRegisterCubit()),
        BlocProvider(create: (_) => AddDriverCubit()),
        BlocProvider(create: (_) => OwnerVehiclesCubit()),
        BlocProvider(create: (_) => FleetDashboardCubit()),
        BlocProvider(create: (_) => DriverDetailCubit()),
        BlocProvider(create: (_) => OwnerWalletCubit()),
        BlocProvider(create: (_) => OwnerBankDetailsCubit()),
        BlocProvider(create: (_) => DeliveryFeedCubit()),
        BlocProvider(create: (_) => QuoteSubmitCubit()),
        BlocProvider(create: (_) => MyQuotesCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (context, themeMode, __) => MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            themeMode: themeMode,
            theme: buildAppThemeLight(),
            darkTheme: buildAppThemeDark(),
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash:        (_) => const SplashScreen(),
              AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
              AppRoutes.login:         (_) => const LoginScreen(),
              AppRoutes.home:          (_) => const HomeScreen(),
              // V2 routes
              AppRoutes.v2PasswordReset:  (_) => const PasswordResetScreen(),
              AppRoutes.v2NotAnOwner:     (_) => const NotAnOwnerScreen(),
              AppRoutes.v2NotADriver:     (_) => const NotADriverScreen(),
              AppRoutes.v2OwnerRegister:  (_) => const OwnerRegisterScreen(),
              AppRoutes.v2OwnerPending:   (_) => const OwnerPendingScreen(),
              AppRoutes.v2OwnerDashboard: (_) => const OwnerMainScreen(),
              AppRoutes.v2OwnerMain:      (_) => const OwnerMainScreen(),
              AppRoutes.v2DriverDisabled: (_) => const DriverDisabledScreen(),
              AppRoutes.v2DriverList:     (_) => const DriversListScreen(),
              AppRoutes.v2AddDriver:      (_) => const AddDriverScreen(),
              AppRoutes.v2DriverDetail:   (ctx) {
                final args = ModalRoute.of(ctx)!.settings.arguments
                    as Map<String, dynamic>;
                return DriverDetailScreen(
                  driverId: args['driver_id'] as String,
                  initialDriver:
                      args['driver'] as Map<String, dynamic>,
                );
              },
              AppRoutes.v2VehicleList: (_) => const OwnerVehiclesScreen(),
              '/dev/gallery': (_) => const WidgetGalleryScreen(),
            },
          ),
        ),
      ),
    );
  }
}
