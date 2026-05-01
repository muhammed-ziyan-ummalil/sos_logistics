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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Delivery History')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (ctx, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (state is HistoryLoaded) {
            if (state.deliveries.isEmpty) {
              return Center(
                child: Text('No deliveries yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              );
            }
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
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
            return Center(child: Text(state.message, style: TextStyle(color: AppColors.error, fontSize: 13.sp)));
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
    final isDelivered = item.state == 'Delivered';
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: (isDelivered ? AppColors.success : AppColors.error).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isDelivered ? AppColors.success : AppColors.error,
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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Text(
                  item.createdAt.substring(0, 10),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
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
                  color: isDelivered ? AppColors.success : AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: (isDelivered ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  item.state,
                  style: TextStyle(
                    color: isDelivered ? AppColors.success : AppColors.error,
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
