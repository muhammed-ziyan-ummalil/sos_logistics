import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerWallet/owner_wallet_cubit.dart';
import '../../../Bloc/QuoteSubmit/quote_submit_cubit.dart';
import '../../../Bloc/QuoteSubmit/quote_submit_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';
import '../account/owner_wallet_screen.dart';

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

  /// Wallet too low for the compensation deposit. Offer a one-tap redirect to the
  /// wallet (mirrors the buyer/seller checkout flow) - on return the sheet stays
  /// open so the owner can retry Send Quote once topped up.
  void _showTopUpDialog(BuildContext sheetCtx, String message) {
    showDialog<void>(
      context: sheetCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Wallet balance too low'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx); // close the dialog first
              await Navigator.of(sheetCtx).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => OwnerWalletCubit()..fetchWallet(),
                    child: const OwnerWalletScreen(),
                  ),
                ),
              );
              // Back on the same picker sheet - the owner can tap Send Quote again.
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
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
                      color: scheme.outline,
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
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Choose which vehicle to send a quote with',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: scheme.onSurface.withValues(alpha: 0.5)),
                ),
                SizedBox(height: 16.h),
                BlocConsumer<QuoteSubmitCubit, QuoteSubmitState>(
                  listener: (ctx, state) {
                    if (state is QuoteSubmitSuccess) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppDesignTokens.success,
                        ),
                      );
                    }
                    if (state is QuoteSubmitError) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Theme.of(ctx).colorScheme.error,
                        ),
                      );
                    }
                    if (state is QuoteSubmitInsufficientFunds) {
                      _showTopUpDialog(ctx, state.message);
                    }
                  },
                  builder: (ctx, state) {
                    if (state is QuoteSubmitLoading) {
                      return Expanded(
                        child: Center(
                          child: SkeletonBox(
                            width: double.infinity,
                            height: 80.h,
                          ),
                        ),
                      );
                    }
                    if (vehicles.isEmpty) {
                      return const Expanded(
                        child: EmptyState(
                          icon: Icons.directions_car_outlined,
                          title: 'No vehicles available for this request.',
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

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: SosCard(
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
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      Text(
                                        '${AppConstants.currencySymbol}${totalFee.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppDesignTokens.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${v['type'] ?? 'Vehicle'} • Driver: ${v['driver_name'] ?? 'Assigned'}',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)),
                                  ),
                                  if (fee.isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    Wrap(
                                      spacing: 4.w,
                                      runSpacing: 4.h,
                                      children: [
                                        SosChip(
                                          label:
                                              'Base: ${AppConstants.currencySymbol}${fee['base_fee'] ?? 0}',
                                          tone: SosTone.neutral,
                                        ),
                                        SosChip(
                                          label:
                                              'Per km: ${AppConstants.currencySymbol}${fee['per_km_fee'] ?? 0}',
                                          tone: SosTone.neutral,
                                        ),
                                        if (extraKm > 0)
                                          SosChip(
                                            label:
                                                'Extra: ${AppConstants.currencySymbol}${fee['extra_km_charge'] ?? 0}',
                                            tone: SosTone.error,
                                          ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: 12.h),
                                  SosButton(
                                    label: 'Send Quote',
                                    onPressed: () =>
                                        ctx.read<QuoteSubmitCubit>().submitQuote(
                                              requestId,
                                              int.tryParse('${v['id']}') ?? 0,
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
}
