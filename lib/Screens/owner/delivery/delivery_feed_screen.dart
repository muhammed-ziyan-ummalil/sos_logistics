import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/DeliveryFeed/delivery_feed_cubit.dart';
import '../../../Bloc/DeliveryFeed/delivery_feed_state.dart';
import '../../../Model/delivery_request_model.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            color: scheme.surface,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(bottom: BorderSide(color: scheme.outline)),
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
                              color: scheme.onSurface,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        BlocBuilder<DeliveryFeedCubit, DeliveryFeedState>(
                          builder: (_, s) => IconButton(
                            icon: Icon(Icons.refresh_rounded,
                                color: scheme.onSurface.withValues(alpha: 0.5),
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
                      labelColor: scheme.primary,
                      unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
                      indicatorColor: scheme.primary,
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
                  return _buildSkeleton();
                }
                if (state is DeliveryFeedError) {
                  return ErrorState(
                    message: state.message,
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
                          context, openRequests, 'No open delivery requests'),
                      _buildRequestList(
                          context, quotedRequests, 'No quoted requests'),
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

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 120.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(
    BuildContext context,
    List<DeliveryRequestModel> requests,
    String emptyMessage,
  ) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: Icons.local_shipping_outlined,
        title: emptyMessage,
      );
    }
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => context.read<DeliveryFeedCubit>().fetchFeed(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _DeliveryRequestCard(request: requests[index]);
        },
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _DeliveryRequestCard extends StatelessWidget {
  final DeliveryRequestModel request;

  const _DeliveryRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final expiryDiff =
        DateTime.tryParse(request.expiresAt)?.difference(DateTime.now());
    final isExpiringSoon =
        expiryDiff != null && !expiryDiff.isNegative && expiryDiff.inMinutes < 60;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SosCard(
        padding: EdgeInsets.zero,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DeliveryRequestDetailScreen(requestId: request.id),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          child: Stack(
            children: [
              // accent top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 3.h, color: scheme.primary),
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
                                iconColor: AppDesignTokens.success,
                                address: request.pickupAddress,
                                textColor: scheme.onSurface,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 6.w),
                                child: Container(
                                  height: 16.h,
                                  width: 1,
                                  color: scheme.outline,
                                ),
                              ),
                              _AddressRow(
                                icon: Icons.location_on_rounded,
                                iconColor: scheme.error,
                                address: request.dropAddress,
                                textColor: scheme.onSurface,
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
                                color: scheme.primary,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '~${request.estimatedDurationMin} min',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: scheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // ── Divider ────────────────────────────────────────────
                    Divider(height: 1, thickness: 0.8, color: scheme.outline),
                    SizedBox(height: 10.h),
                    // ── Meta row ───────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Request type badge
                        SosChip(
                          label: request.requestType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          tone: SosTone.info,
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
                                    ? scheme.error
                                    : AppDesignTokens.warning,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                _formatExpiry(expiryDiff),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isExpiringSoon
                                      ? scheme.error
                                      : AppDesignTokens.warning,
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

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.address,
    required this.textColor,
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
