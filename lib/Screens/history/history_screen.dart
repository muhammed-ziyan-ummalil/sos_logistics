import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/History/history_cubit.dart';
import '../../Bloc/History/history_state.dart';
import '../../Model/delivery_model.dart';
import '../../core/app_theme.dart';

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
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(title: const Text('Delivery History')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (ctx, state) {
          if (state is HistoryLoading) {
            return Center(child: CircularProgressIndicator(color: AppTheme.accent(context)));
          }
          if (state is HistoryLoaded) {
            if (state.deliveries.isEmpty) {
              return Center(
                child: Text(
                  'No deliveries yet.',
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14.sp),
                ),
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
            return Center(
              child: Text(state.message, style: TextStyle(color: AppTheme.error(context), fontSize: 13.sp)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DeliveryHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDelivered  = item.state == 'Delivered';
    final statusColor  = isDelivered ? AppTheme.success(context) : AppTheme.error(context);

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: statusColor,
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
                '₹${item.fee.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDelivered ? AppTheme.success(context) : AppTheme.textSecondary(context),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  item.state,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
