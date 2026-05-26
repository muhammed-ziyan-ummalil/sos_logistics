import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/DeliveryFeed/delivery_feed_cubit.dart';
import '../../../Bloc/DeliveryFeed/delivery_feed_state.dart';
import '../../../Model/delivery_request_model.dart';
import '../../../core/app_theme.dart';

import 'delivery_request_detail_screen.dart';

class DeliveryFeedScreen extends StatefulWidget {
  const DeliveryFeedScreen({super.key});

  @override
  State<DeliveryFeedScreen> createState() => _DeliveryFeedScreenState();
}

class _DeliveryFeedScreenState extends State<DeliveryFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<DeliveryFeedCubit>().fetchFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            color: surfaceColor,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Available Deliveries',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        BlocBuilder<DeliveryFeedCubit, DeliveryFeedState>(
                          builder: (_, s) => IconButton(
                            icon: Icon(Icons.refresh_rounded,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppLightColors.textSecondary,
                                size: 20.r),
                            onPressed: s is DeliveryFeedLoading
                                ? null
                                : () => context
                                    .read<DeliveryFeedCubit>()
                                    .fetchFeed(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    TabBar(
                      controller: _tabController,
                      labelColor: accentColor,
                      unselectedLabelColor:
                          isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
                      indicatorColor: accentColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w600),
                      unselectedLabelStyle:
                          TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400),
                      tabs: const [
                        Tab(text: 'Open'),
                        Tab(text: 'Quoted'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<DeliveryFeedCubit, DeliveryFeedState>(
              builder: (context, state) {
                if (state is DeliveryFeedInitial ||
                    state is DeliveryFeedLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2.5),
                  );
                }
                if (state is DeliveryFeedError) {
                  return _ErrorView(
                    message: state.message,
                    isDark: isDark,
                    onRetry: () =>
                        context.read<DeliveryFeedCubit>().fetchFeed(),
                  );
                }
                if (state is DeliveryFeedLoaded) {
                  final openRequests = state.requests
                      .where((r) => r.status == 'open')
                      .toList();
                  final quotedRequests = state.requests
                      .where((r) => r.status == 'quoted')
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(
                          context, openRequests, 'No open delivery requests',
                          isDark: isDark),
                      _buildRequestList(
                          context, quotedRequests, 'No quoted requests',
                          isDark: isDark),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(
    BuildContext context,
    List<DeliveryRequestModel> requests,
    String emptyMessage, {
    required bool isDark,
  }) {
    if (requests.isEmpty) {
      return _EmptyView(message: emptyMessage, isDark: isDark);
    }
    return RefreshIndicator(
      color: isDark ? AppColors.accent : AppLightColors.accent,
      backgroundColor: isDark ? AppColors.card : AppLightColors.card,
      onRefresh: () => context.read<DeliveryFeedCubit>().fetchFeed(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _DeliveryRequestCard(
              request: requests[index], isDark: isDark);
        },
      ),
    );
  }
}

// ─── Empty view ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  final bool isDark;
  const _EmptyView({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: dividerColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.local_shipping_outlined,
                size: 32.r, color: dividerColor),
          ),
          SizedBox(height: 16.h),
          Text(message,
              style:
                  TextStyle(color: textSecondary, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _DeliveryRequestCard extends StatelessWidget {
  final DeliveryRequestModel request;
  final bool isDark;

  const _DeliveryRequestCard(
      {required this.request, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    final expiryDiff =
        DateTime.tryParse(request.expiresAt)?.difference(DateTime.now());
    final isExpiringSoon =
        expiryDiff != null && !expiryDiff.isNegative && expiryDiff.inMinutes < 60;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DeliveryRequestDetailScreen(requestId: request.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Stack(
              children: [
                // accent top accent bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 3.h, color: accentColor),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h + 3.h, 16.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Route row ──────────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AddressRow(
                                  icon: Icons.radio_button_checked_rounded,
                                  iconColor: AppColors.success,
                                  address: request.pickupAddress,
                                  textColor: textPrimary,
                                  isDark: isDark,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 6.w),
                                  child: Container(
                                    height: 16.h,
                                    width: 1,
                                    color: dividerColor,
                                  ),
                                ),
                                _AddressRow(
                                  icon: Icons.location_on_rounded,
                                  iconColor:
                                      isDark ? AppColors.error : AppLightColors.error,
                                  address: request.dropAddress,
                                  textColor: textPrimary,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Distance / duration
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${request.distanceKm.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                '~${request.estimatedDurationMin} min',
                                style: TextStyle(
                                    fontSize: 11.sp, color: textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      // ── Divider ────────────────────────────────────────────
                      Divider(height: 1, thickness: 0.8, color: dividerColor),
                      SizedBox(height: 10.h),
                      // ── Meta row ───────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Request type badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border:
                                  Border.all(color: accentColor.withOpacity(0.25)),
                            ),
                            child: Text(
                              request.requestType
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor),
                            ),
                          ),
                          // Expiry
                          if (expiryDiff != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12.r,
                                  color: isExpiringSoon
                                      ? (isDark
                                          ? AppColors.error
                                          : AppLightColors.error)
                                      : (isDark
                                          ? AppColors.warning
                                          : AppLightColors.warning),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  _formatExpiry(expiryDiff),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isExpiringSoon
                                        ? (isDark
                                            ? AppColors.error
                                            : AppLightColors.error)
                                        : (isDark
                                            ? AppColors.warning
                                            : AppLightColors.warning),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatExpiry(Duration diff) {
    if (diff.isNegative) return 'Expired';
    if (diff.inHours > 0) {
      return 'Expires in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return 'Expires in ${diff.inMinutes}m';
  }
}

// ─── Address row ──────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String address;
  final Color textColor;
  final bool isDark;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.address,
    required this.textColor,
    required this.isDark,
  });

  String _truncate(String a) {
    final parts = a.split(',');
    return parts.length > 2
        ? '${parts[0].trim()}, ${parts[1].trim()}'
        : a;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13.r, color: iconColor),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            _truncate(address),
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorView(
      {required this.message, required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final errorColor = isDark ? AppColors.error : AppLightColors.error;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child:
                  Icon(Icons.wifi_off_rounded, color: errorColor, size: 28.r),
            ),
            SizedBox(height: 16.h),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 13.sp)),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
