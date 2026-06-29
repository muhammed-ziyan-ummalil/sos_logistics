import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../core/dashboard_back_handler.dart';
import '../../widgets/widgets.dart';
import '../delivery/active_delivery_screen.dart';
import '../history/history_screen.dart';
import '../notifications/notification_bell.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with DashboardBackHandler {
  int _tab = 0;
  Timer? _pollTimer;

  @override
  int get selectedTabIndex => _tab;

  @override
  void onBackToFirstTab() => setState(() => _tab = 0);

  final List<Widget> _pages = const [
    _DashboardTab(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
    // Live-refresh the assigned-delivery view so a newly assigned job appears
    // without the driver leaving and re-entering the home screen.
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _poll() {
    if (!mounted) return;
    context.read<ActiveDeliveryCubit>().fetchActiveDelivery();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => handleDashboardPop(didPop),
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: IndexedStack(index: _tab, children: _pages),
        bottomNavigationBar: SosBottomNav(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            SosNavItem(icon: Icons.home_rounded, label: 'Home'),
            SosNavItem(icon: Icons.history_rounded, label: 'History'),
            SosNavItem(icon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.accent(context),
        backgroundColor: AppTheme.card(context),
        onRefresh: () async {
          context.read<ActiveDeliveryCubit>().fetchActiveDelivery();
        },
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Driver Dashboard',
                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
                const NotificationBell(role: 'driver'),
              ],
            ),
            SizedBox(height: 24.h),

            // ── Assigned delivery ────────────────────────────────────────
            // The owner assigns vehicles + deliveries to the driver. The driver
            // only performs the delivery actions (OTP, status, photos); there
            // is no online/offline toggle and no offer feed.
            BlocBuilder<ActiveDeliveryCubit, ActiveDeliveryState>(
              builder: (ctx, state) {
                if (state is ActiveDeliveryLoaded) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
                    ),
                    child: _ActiveDeliveryBanner(),
                  );
                }
                if (state is ActiveDeliveryError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () => ctx.read<ActiveDeliveryCubit>().fetchActiveDelivery(),
                  );
                }
                if (state is ActiveDeliveryInitial || state is ActiveDeliveryLoading) {
                  return _LoadingCard();
                }
                // ActiveDeliveryNone (or any post-completion state): empty state.
                return _NoDeliveryCard();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active delivery banner ───────────────────────────────────────────────────
class _ActiveDeliveryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return SosCard(
      onTap: null, // tap handled by GestureDetector parent
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: accent, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Delivery',
                  style: TextStyle(color: accent, fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Tap to continue',
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 14.r),
        ],
      ),
    );
  }
}

// ── Loading card ─────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SosCard(
      padding: EdgeInsets.all(32.r),
      child: Center(
        child: SizedBox(
          width: 28.r,
          height: 28.r,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accent(context),
          ),
        ),
      ),
    );
  }
}

// ── No active delivery card ──────────────────────────────────────────────────
class _NoDeliveryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SosCard(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined, color: AppTheme.textSecondary(context), size: 48.r),
          SizedBox(height: 16.h),
          Text(
            'No active delivery',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your owner will assign deliveries to you. Pull down to refresh.',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
