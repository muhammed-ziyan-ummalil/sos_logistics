import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Availability/availability_cubit.dart';
import '../../Bloc/Availability/availability_state.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../delivery/active_delivery_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Timer? _pollTimer;

  final List<Widget> _pages = const [
    _DashboardTab(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
    // Live-refresh the active-delivery banner so a newly assigned job appears
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
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
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
                const _AvailabilityToggle(),
              ],
            ),
            SizedBox(height: 24.h),

            // ── Active delivery banner ───────────────────────────────────
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
                return const SizedBox.shrink();
              },
            ),

            // Drivers now receive delivery jobs via the owner quote marketplace
            _WaitingCard(),
          ],
        ),
      ),
    );
  }
}

// ── Availability toggle ──────────────────────────────────────────────────────
class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AvailabilityCubit, AvailabilityState>(
      builder: (ctx, state) {
        final isOnline  = state is AvailabilityUpdated && state.isOnline;
        final isLoading = state is AvailabilityLoading;
        final onColor   = AppTheme.success(context);
        final offColor  = AppTheme.textSecondary(context);
        final dotColor  = isOnline ? onColor : offColor;

        return GestureDetector(
          onTap: isLoading ? null : () => ctx.read<AvailabilityCubit>().toggle(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppTheme.success(context).withOpacity(0.12)
                  : AppTheme.card(context),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isOnline ? onColor.withOpacity(0.5) : AppTheme.divider(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 12.r,
                    height: 12.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.accent(context),
                    ),
                  )
                else
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                  ),
                SizedBox(width: 6.w),
                Text(
                  isLoading ? '...' : (isOnline ? 'Online' : 'Offline'),
                  style: TextStyle(
                    color: isOnline ? onColor : offColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Active delivery banner ───────────────────────────────────────────────────
class _ActiveDeliveryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final primary = AppTheme.primary(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primary.withOpacity(0.4)),
      ),
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

// ── Waiting card ─────────────────────────────────────────────────────────────
class _WaitingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_tethering_rounded, color: AppTheme.textSecondary(context), size: 48.r),
          SizedBox(height: 16.h),
          Text(
            'Waiting for orders...',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Go online to start receiving delivery offers.',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
