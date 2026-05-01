import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'Bloc/Auth/driver_auth_cubit.dart';
import 'Bloc/Auth/owner_auth_cubit.dart';
import 'Bloc/Auth/auth_cubit.dart';
import 'Bloc/Auth/password_reset_cubit.dart';
import 'Bloc/Availability/availability_cubit.dart';
import 'Bloc/Offer/offer_cubit.dart';
import 'Bloc/ActiveDelivery/active_delivery_cubit.dart';
import 'Bloc/History/history_cubit.dart';
import 'Bloc/Earnings/earnings_cubit.dart';
import 'Bloc/OwnerOnboarding/owner_register_cubit.dart';
import 'Bloc/OwnerDrivers/add_driver_cubit.dart';
import 'Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import 'Screens/auth/splash_screen.dart';
import 'Screens/auth/role_selection_screen.dart';
import 'Screens/auth/login_screen.dart';
import 'Screens/auth/password_reset_screen.dart';
import 'Screens/auth/not_an_owner_screen.dart';
import 'Screens/auth/not_a_driver_screen.dart';
import 'Screens/home/home_screen.dart';
import 'Screens/owner/owner_home_screen.dart';
import 'Screens/owner/owner_pending_screen.dart';
import 'Screens/owner/register/owner_register_screen.dart';
import 'Screens/owner/drivers/drivers_list_screen.dart';
import 'Screens/owner/drivers/add_driver_screen.dart';
import 'Screens/driver/driver_disabled_screen.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SOSLogisticsApp());
}

class SOSLogisticsApp extends StatelessWidget {
  const SOSLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Legacy cubits
        BlocProvider(create: (_) => DriverAuthCubit()),
        BlocProvider(create: (_) => OwnerAuthCubit()),
        BlocProvider(create: (_) => AvailabilityCubit()),
        BlocProvider(create: (_) => OfferCubit()),
        BlocProvider(create: (_) => ActiveDeliveryCubit()),
        BlocProvider(create: (_) => HistoryCubit()),
        BlocProvider(create: (_) => EarningsCubit()),
        // V2 cubits
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => PasswordResetCubit()),
        BlocProvider(create: (_) => OwnerRegisterCubit()),
        BlocProvider(create: (_) => AddDriverCubit()),
        BlocProvider(create: (_) => OwnerVehiclesCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          initialRoute: AppRoutes.splash,
          routes: {
            // Legacy routes
            AppRoutes.splash:        (_) => const SplashScreen(),
            AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
            AppRoutes.login:         (_) => const LoginScreen(),
            AppRoutes.home:          (_) => const HomeScreen(),
            AppRoutes.ownerHome:     (_) => const OwnerHomeScreen(),
            // V2 routes
            AppRoutes.v2PasswordReset:  (_) => const PasswordResetScreen(),
            AppRoutes.v2NotAnOwner:     (_) => const NotAnOwnerScreen(),
            AppRoutes.v2NotADriver:     (_) => const NotADriverScreen(),
            AppRoutes.v2OwnerRegister:  (_) => const OwnerRegisterScreen(),
            AppRoutes.v2OwnerPending:   (_) => const OwnerPendingScreen(),
            AppRoutes.v2OwnerDashboard: (_) => const OwnerHomeScreen(),
            AppRoutes.v2DriverDisabled: (_) => const DriverDisabledScreen(),
            AppRoutes.v2DriverList:     (_) => const DriversListScreen(),
            AppRoutes.v2AddDriver:      (_) => const AddDriverScreen(),
          },
        ),
      ),
    );
  }
}
