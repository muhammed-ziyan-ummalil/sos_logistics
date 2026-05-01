import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../Bloc/Earnings/earnings_cubit.dart';
import '../../Bloc/Earnings/earnings_state.dart';
import '../../Model/earnings_model.dart';
import '../../core/app_theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EarningsCubit>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings')),
      body: BlocBuilder<EarningsCubit, EarningsState>(
        builder: (ctx, state) {
          if (state is EarningsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (state is EarningsLoaded) {
            return _EarningsBody(data: state.data);
          }
          if (state is EarningsError) {
            return Center(child: Text(state.message, style: TextStyle(color: AppColors.error, fontSize: 13.sp)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EarningsBody extends StatelessWidget {
  final EarningsData data;
  const _EarningsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: () => context.read<EarningsCubit>().fetch(),
      child: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          // Total card
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Text('Total Earnings (30 days)', style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                SizedBox(height: 8.h),
                Text(
                  '₹${data.totalEarnings.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          if (data.daily.isNotEmpty) ...[
            Text('Daily Breakdown', style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 12.h),

            // Bar chart
            SizedBox(
              height: 160.h,
              child: BarChart(
                BarChartData(
                  backgroundColor: AppColors.card,
                  barGroups: data.daily.reversed.take(7).toList().asMap().entries.map((e) {
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: e.value.netEarnings,
                        color: AppColors.accent,
                        width: 14.w,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                      ),
                    ]);
                  }).toList(),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final reversed = data.daily.reversed.take(7).toList();
                          final i = v.toInt();
                          if (i >= reversed.length) return const SizedBox.shrink();
                          final d = reversed[i].date;
                          return Text(d.substring(5), style: TextStyle(color: AppColors.textSecondary, fontSize: 9.sp));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // List
            ...data.daily.map((d) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 16.r),
                  SizedBox(width: 10.w),
                  Text(d.date, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
                  const Spacer(),
                  Text(
                    '${d.deliveries} trip${d.deliveries != 1 ? 's' : ''}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    '₹${d.netEarnings.toStringAsFixed(2)}',
                    style: TextStyle(color: AppColors.success, fontSize: 14.sp, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )),
          ] else
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: Text('No earnings in the last 30 days.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
              ),
            ),
        ],
      ),
    );
  }
}
