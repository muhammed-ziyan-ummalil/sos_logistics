import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/QuoteSubmit/quote_submit_cubit.dart';
import '../../../Bloc/QuoteSubmit/quote_submit_state.dart';
import '../../../core/app_theme.dart';

class VehiclePickerBottomSheet extends StatelessWidget {
  final int requestId;
  final List<Map<String, dynamic>> vehicles;

  const VehiclePickerBottomSheet({
    super.key,
    required this.requestId,
    required this.vehicles,
  });

  static Future<void> show(
    BuildContext context,
    int requestId,
    List<Map<String, dynamic>> vehicles,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<QuoteSubmitCubit>(),
        child: VehiclePickerBottomSheet(
          requestId: requestId,
          vehicles: vehicles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : AppLightColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Select Vehicle',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Choose which vehicle to send a quote with',
                  style: TextStyle(fontSize: 12.sp, color: textSecondary),
                ),
                SizedBox(height: 16.h),
                BlocConsumer<QuoteSubmitCubit, QuoteSubmitState>(
                  listener: (ctx, state) {
                    if (state is QuoteSubmitSuccess) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                    if (state is QuoteSubmitError) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor:
                              isDark ? AppColors.error : AppLightColors.error,
                        ),
                      );
                    }
                  },
                  builder: (ctx, state) {
                    if (state is QuoteSubmitLoading) {
                      return Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: accentColor),
                        ),
                      );
                    }
                    if (vehicles.isEmpty) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            'No vehicles available for this request.',
                            style: TextStyle(
                                fontSize: 13.sp, color: textSecondary),
                          ),
                        ),
                      );
                    }
                    return Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: vehicles.length,
                        itemBuilder: (ctx, i) {
                          final v = vehicles[i];
                          final fee =
                              v['fee_breakdown'] as Map<String, dynamic>? ?? {};
                          final totalFee =
                              double.tryParse('${fee['total_fee'] ?? 0}') ?? 0;
                          final extraKm =
                              double.tryParse('${fee['extra_km'] ?? 0}') ?? 0;

                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: dividerColor, width: 0.8),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        v['registration_number'] ?? 'Vehicle',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '₹${totalFee.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${v['type'] ?? 'Vehicle'} • Driver: ${v['driver_name'] ?? 'Assigned'}',
                                    style: TextStyle(
                                        fontSize: 12.sp, color: textSecondary),
                                  ),
                                  if (fee.isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    Wrap(
                                      spacing: 4.w,
                                      runSpacing: 4.h,
                                      children: [
                                        _chip('Base: ₹${fee['base_fee'] ?? 0}',
                                            isDark: isDark),
                                        _chip(
                                            'Per km: ₹${fee['per_km_fee'] ?? 0}',
                                            isDark: isDark),
                                        if (extraKm > 0)
                                          _chip(
                                            'Extra: ₹${fee['extra_km_charge'] ?? 0}',
                                            isDark: isDark,
                                            red: true,
                                          ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: 12.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          ctx.read<QuoteSubmitCubit>().submitQuote(
                                                requestId,
                                                int.tryParse('${v['id']}') ?? 0,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                      ),
                                      child: const Text('Send Quote'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String text, {required bool isDark, bool red = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: red
            ? (isDark
                ? AppColors.error.withOpacity(0.15)
                : AppLightColors.error.withOpacity(0.1))
            : (isDark ? AppColors.divider : AppLightColors.divider)
                .withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: red
              ? (isDark ? AppColors.error : AppLightColors.error)
              : (isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
        ),
      ),
    );
  }
}
