import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/MyQuotes/my_quotes_cubit.dart';
import '../../../Bloc/MyQuotes/my_quotes_state.dart';
import '../../../Model/delivery_quote_model.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

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
                            'My Quotes',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        BlocBuilder<MyQuotesCubit, MyQuotesState>(
                          builder: (_, s) => IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.5),
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
                      labelColor: scheme.primary,
                      unselectedLabelColor:
                          scheme.onSurface.withValues(alpha: 0.5),
                      indicatorColor: scheme.primary,
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
                  return _buildSkeleton();
                }
                if (state is MyQuotesError) {
                  return ErrorState(
                    message: state.message,
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
                      _buildList(context, pending, 'No pending quotes'),
                      _buildList(context, accepted, 'No accepted quotes'),
                      _buildList(context, history, 'No quote history'),
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
        child: SkeletonBox(width: double.infinity, height: 110.h),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<DeliveryQuoteModel> quotes,
    String emptyMessage,
  ) {
    if (quotes.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: emptyMessage,
      );
    }
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => context.read<MyQuotesCubit>().fetchMyQuotes(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        itemCount: quotes.length,
        itemBuilder: (context, index) =>
            _QuoteCard(quote: quotes[index]),
      ),
    );
  }
}

// ─── Quote card ───────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final DeliveryQuoteModel quote;

  const _QuoteCard({required this.quote});

  SosTone _statusTone(String status) {
    switch (status) {
      case 'pending':
        return SosTone.warning;
      case 'accepted':
        return SosTone.success;
      case 'rejected':
        return SosTone.error;
      default:
        return SosTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SosCard(
        padding: EdgeInsets.zero,
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
                            color: scheme.onSurface,
                          ),
                        ),
                        SosChip(
                          label: quote.status.toUpperCase(),
                          tone: _statusTone(quote.status),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // ── Vehicle row ─────────────────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.directions_car_outlined,
                            size: 13.r,
                            color: scheme.onSurface.withValues(alpha: 0.5)),
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
                                fontSize: 12.sp,
                                color: scheme.onSurface.withValues(alpha: 0.5)),
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
                              size: 13.r,
                              color: scheme.onSurface.withValues(alpha: 0.5)),
                          SizedBox(width: 5.w),
                          Text(
                            'Driver: ${quote.driverName}',
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: scheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 10.h),
                    Divider(height: 1, thickness: 0.8, color: scheme.outline),
                    SizedBox(height: 10.h),

                    // ── Fee row ─────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Distance chip
                        SosChip(
                          label: '${quote.distanceKm.toStringAsFixed(1)} km',
                          tone: SosTone.info,
                        ),
                        // Total fee
                        Text(
                          '${AppConstants.currencySymbol}${quote.totalFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),

                    // ── Fee breakdown ───────────────────────────────────────
                    if (quote.extraKm > 0) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Base ${AppConstants.currencySymbol}${quote.baseFee.toStringAsFixed(0)}'
                        ' + Extra ${quote.extraKm.toStringAsFixed(1)} km'
                        ' (${AppConstants.currencySymbol}${quote.extraKmCharge.toStringAsFixed(0)})',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: scheme.onSurface.withValues(alpha: 0.5)),
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
