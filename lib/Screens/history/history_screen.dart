import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/History/history_cubit.dart';
import '../../Bloc/History/history_state.dart';
import '../../Model/delivery_model.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../widgets/widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SosAppBar(title: 'Delivery History'),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (ctx, state) {
          if (state is HistoryLoading) {
            return ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, __) => SosCard(
                child: Row(
                  children: [
                    SkeletonBox(width: 40.r, height: 40.r, radius: 20),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 14.h, width: double.infinity),
                          SizedBox(height: 6.h),
                          SkeletonBox(height: 11.h, width: 80.w),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonBox(height: 14.h, width: 60.w),
                        SizedBox(height: 6.h),
                        SkeletonBox(height: 20.h, width: 70.w, radius: AppDesignTokens.radiusS),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is HistoryLoaded) {
            if (state.deliveries.isEmpty) {
              return const EmptyState(
                icon: Icons.history_rounded,
                title: 'No deliveries yet',
                subtitle: 'Completed deliveries will appear here.',
              );
            }
            return RefreshIndicator(
              color: AppTheme.accent(context),
              backgroundColor: AppTheme.card(context),
              onRefresh: () => ctx.read<HistoryCubit>().fetch(),
              child: ListView.separated(
                padding: EdgeInsets.all(16.r),
                itemCount: state.deliveries.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) => _HistoryTile(item: state.deliveries[i]),
              ),
            );
          }
          if (state is HistoryError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<HistoryCubit>().fetch(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

SosTone _statusTone(String state) {
  switch (state.toLowerCase()) {
    case 'completed':
    case 'delivered':
      return SosTone.success;
    case 'cancelled':
      return SosTone.error;
    case 'in-progress':
    case 'inprogress':
    case 'in_progress':
    case 'intransit':
    case 'in_transit':
      return SosTone.info;
    default:
      return SosTone.neutral;
  }
}

class _HistoryTile extends StatelessWidget {
  final DeliveryHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final tone = _statusTone(item.state);
    final isDelivered = item.state == 'Delivered';
    final feeColor = isDelivered ? AppTheme.success(context) : AppTheme.textSecondary(context);

    return SosCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: (isDelivered ? AppTheme.success(context) : AppTheme.error(context))
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isDelivered ? AppTheme.success(context) : AppTheme.error(context),
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dropAddress,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Text(
                  item.createdAt.substring(0, 10),
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppConstants.currencySymbol}${item.fee.toStringAsFixed(2)}',
                style: TextStyle(
                  color: feeColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3.h),
              SosChip(label: item.state, tone: tone),
            ],
          ),
        ],
      ),
    );
  }
}
