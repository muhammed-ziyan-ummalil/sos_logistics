import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'Bloc/Auth/driver_auth_cubit.dart';
import 'Bloc/Availability/availability_cubit.dart';
import 'Bloc/Offer/offer_cubit.dart';
import 'Bloc/ActiveDelivery/active_delivery_cubit.dart';
import 'Bloc/History/history_cubit.dart';
import 'Bloc/Earnings/earnings_cubit.dart';
import 'Screens/auth/splash_screen.dart';
import 'Screens/auth/login_screen.dart';
import 'Screens/home/home_screen.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'services/firebase_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseNotificationService.init();
  await FirebaseNotificationService.uploadToken();

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
        BlocProvider(create: (_) => DriverAuthCubit()),
        BlocProvider(create: (_) => AvailabilityCubit()),
        BlocProvider(create: (_) => OfferCubit()),
        BlocProvider(create: (_) => ActiveDeliveryCubit()),
        BlocProvider(create: (_) => HistoryCubit()),
        BlocProvider(create: (_) => EarningsCubit()),
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
            AppRoutes.splash:  (_) => const SplashScreen(),
            AppRoutes.login:   (_) => const LoginScreen(),
            AppRoutes.home:    (_) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}
