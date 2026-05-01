import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/Availability/availability_cubit.dart';
import '../../Bloc/Availability/availability_state.dart';
import '../../Bloc/Offer/offer_cubit.dart';
import '../../Bloc/Offer/offer_state.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../delivery/active_delivery_screen.dart';
import '../earnings/earnings_screen.dart';
import '../history/history_screen.dart';
import '../offer/offer_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    HistoryScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    context.read<OfferCubit>().fetchActiveOffer();
    context.read<ActiveDeliveryCubit>().fetchActiveDelivery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _tab, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Earnings'),
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
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          context.read<OfferCubit>().fetchActiveOffer();
          context.read<ActiveDeliveryCubit>().fetchActiveDelivery();
        },
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Driver Dashboard',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
                // Online/Offline toggle
                const _AvailabilityToggle(),
              ],
            ),
            SizedBox(height: 24.h),

            // Active delivery banner
            BlocBuilder<ActiveDeliveryCubit, ActiveDeliveryState>(
              builder: (ctx, state) {
                if (state is ActiveDeliveryLoaded) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
                    ),
                    child: _ActiveDeliveryBanner(delivery: state.delivery),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Offer card
            BlocBuilder<OfferCubit, OfferState>(
              builder: (ctx, state) {
                if (state is OfferAvailable) {
                  return OfferCard(
                    offer: state.offer,
                    onAccept: () => ctx.read<OfferCubit>().acceptOffer(state.offer.offerId),
                    onReject: () => ctx.read<OfferCubit>().rejectOffer(state.offer.offerId),
                  );
                }
                if (state is OfferAccepted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
                    );
                    ctx.read<OfferCubit>().fetchActiveOffer();
                  });
                }
                return _WaitingCard();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AvailabilityCubit, AvailabilityState>(
      builder: (ctx, state) {
        final isOnline  = state is AvailabilityUpdated && state.isOnline;
        final isLoading = state is AvailabilityLoading;
        return GestureDetector(
          onTap: isLoading ? null : () => ctx.read<AvailabilityCubit>().toggle(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success.withOpacity(0.15) : AppColors.card,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isOnline ? AppColors.success : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 12.r,
                    height: 12.r,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                  )
                else
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                SizedBox(width: 6.w),
                Text(
                  isLoading ? '...' : (isOnline ? 'Online' : 'Offline'),
                  style: TextStyle(
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
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

class _ActiveDeliveryBanner extends StatelessWidget {
  final dynamic delivery;
  const _ActiveDeliveryBanner({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: AppColors.accent, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Delivery', style: TextStyle(color: AppColors.accent, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                Text('Tap to continue', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.accent, size: 14.r),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_tethering_rounded, color: AppColors.textSecondary, size: 48.r),
          SizedBox(height: 16.h),
          Text(
            'Waiting for orders...',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            'Go online to start receiving delivery offers.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
