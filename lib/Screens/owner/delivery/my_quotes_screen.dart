import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/MyQuotes/my_quotes_cubit.dart';
import '../../../Bloc/MyQuotes/my_quotes_state.dart';
import '../../../Model/delivery_quote_model.dart';
import '../../../core/app_theme.dart';

class MyQuotesScreen extends StatefulWidget {
  const MyQuotesScreen({super.key});

  @override
  State<MyQuotesScreen> createState() => _MyQuotesScreenState();
}

class _MyQuotesScreenState extends State<MyQuotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MyQuotesCubit>().fetchMyQuotes();
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
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
                            'My Quotes',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        BlocBuilder<MyQuotesCubit, MyQuotesState>(
                          builder: (_, s) => IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppLightColors.textSecondary,
                              size: 20.r,
                            ),
                            onPressed: s is MyQuotesLoading
                                ? null
                                : () =>
                                    context.read<MyQuotesCubit>().fetchMyQuotes(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    TabBar(
                      controller: _tabController,
                      labelColor: accentColor,
                      unselectedLabelColor: isDark
                          ? AppColors.textSecondary
                          : AppLightColors.textSecondary,
                      indicatorColor: accentColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w400),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Accepted'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<MyQuotesCubit, MyQuotesState>(
              builder: (context, state) {
                if (state is MyQuotesInitial || state is MyQuotesLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2.5),
                  );
                }
                if (state is MyQuotesError) {
                  return _ErrorView(
                    message: state.message,
                    isDark: isDark,
                    onRetry: () =>
                        context.read<MyQuotesCubit>().fetchMyQuotes(),
                  );
                }
                if (state is MyQuotesLoaded) {
                  final pending = state.quotes
                      .where((q) => q.status == 'pending')
                      .toList();
                  final accepted = state.quotes
                      .where((q) => q.status == 'accepted')
                      .toList();
                  final history = state.quotes
                      .where((q) =>
                          !['pending', 'accepted'].contains(q.status))
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(context, pending, 'No pending quotes',
                          isDark: isDark),
                      _buildList(context, accepted, 'No accepted quotes',
                          isDark: isDark),
                      _buildList(context, history, 'No quote history',
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

  Widget _buildList(
    BuildContext context,
    List<DeliveryQuoteModel> quotes,
    String emptyMessage, {
    required bool isDark,
  }) {
    if (quotes.isEmpty) {
      return _EmptyView(message: emptyMessage, isDark: isDark);
    }
    return RefreshIndicator(
      color: isDark ? AppColors.accent : AppLightColors.accent,
      backgroundColor: isDark ? AppColors.card : AppLightColors.card,
      onRefresh: () => context.read<MyQuotesCubit>().fetchMyQuotes(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        itemCount: quotes.length,
        itemBuilder: (context, index) =>
            _QuoteCard(quote: quotes[index], isDark: isDark),
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
            child: Icon(Icons.receipt_long_outlined,
                size: 32.r, color: dividerColor),
          ),
          SizedBox(height: 16.h),
          Text(message,
              style: TextStyle(color: textSecondary, fontSize: 13.sp)),
        ],
      ),
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

// ─── Quote card ───────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final DeliveryQuoteModel quote;
  final bool isDark;

  const _QuoteCard({required this.quote, required this.isDark});

  Color _statusColor(String status, bool dark) {
    switch (status) {
      case 'pending':
        return dark ? AppColors.warning : AppLightColors.warning;
      case 'accepted':
        return dark ? AppColors.success : AppLightColors.success;
      case 'rejected':
        return dark ? AppColors.error : AppLightColors.error;
      default:
        return dark ? AppColors.textSecondary : AppLightColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final statusColor = _statusColor(quote.status, isDark);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
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
              // accent top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 3.h, color: accentColor),
              ),
              Padding(
                padding:
                    EdgeInsets.fromLTRB(16.w, 16.h + 3.h, 16.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: ID + status badge ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quote #${quote.id}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                                color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            quote.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // ── Vehicle row ─────────────────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.directions_car_outlined,
                            size: 13.r, color: textSecondary),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            [
                              quote.vehicleType ?? 'Vehicle',
                              if (quote.registrationNumber != null &&
                                  quote.registrationNumber!.isNotEmpty)
                                quote.registrationNumber!,
                            ].join(' • '),
                            style: TextStyle(
                                fontSize: 12.sp, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // ── Driver row (if available) ───────────────────────────
                    if (quote.driverName != null &&
                        quote.driverName!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13.r, color: textSecondary),
                          SizedBox(width: 5.w),
                          Text(
                            'Driver: ${quote.driverName}',
                            style: TextStyle(
                                fontSize: 12.sp, color: textSecondary),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 10.h),
                    Divider(height: 1, thickness: 0.8, color: dividerColor),
                    SizedBox(height: 10.h),

                    // ── Fee row ─────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Distance chip
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                                color: accentColor.withOpacity(0.25)),
                          ),
                          child: Text(
                            '${quote.distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                        // Total fee
                        Text(
                          '₹${quote.totalFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),

                    // ── Fee breakdown ───────────────────────────────────────
                    if (quote.extraKm > 0) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Base ₹${quote.baseFee.toStringAsFixed(0)}'
                        ' + Extra ${quote.extraKm.toStringAsFixed(1)} km'
                        ' (₹${quote.extraKmCharge.toStringAsFixed(0)})',
                        style:
                            TextStyle(fontSize: 11.sp, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
