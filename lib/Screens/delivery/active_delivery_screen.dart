import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../Model/delivery_model.dart';
import '../../core/app_theme.dart';
import 'otp_entry_sheet.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ActiveDeliveryCubit>().fetchActiveDelivery();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveDeliveryCubit, ActiveDeliveryState>(
      listener: (ctx, state) {
        if (state is ActiveDeliveryCompleted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('Delivery completed! Great work.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(ctx);
        } else if (state is ActiveDeliveryOtpError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Active Delivery'),
          backgroundColor: AppColors.surface,
        ),
        body: BlocBuilder<ActiveDeliveryCubit, ActiveDeliveryState>(
          builder: (ctx, state) {
            if (state is ActiveDeliveryLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (state is ActiveDeliveryNone) {
              return Center(
                child: Text('No active delivery.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              );
            }
            if (state is ActiveDeliveryLoaded) {
              return _DeliveryDetail(delivery: state.delivery);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _DeliveryDetail extends StatefulWidget {
  final ActiveDelivery delivery;
  const _DeliveryDetail({required this.delivery});

  @override
  State<_DeliveryDetail> createState() => _DeliveryDetailState();
}

class _DeliveryDetailState extends State<_DeliveryDetail> {
  bool _pickupOtpGenerated = false;
  bool _dropOtpGenerated   = false;
  final _pickupOtpController = TextEditingController();
  final _dropOtpController   = TextEditingController();

  @override
  void dispose() {
    _pickupOtpController.dispose();
    _dropOtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery    = widget.delivery;
    final isAssigned  = delivery.state == 'Assigned';
    final isInTransit = delivery.state == 'InTransit' || delivery.state == 'PickedUp';

    return BlocListener<ActiveDeliveryCubit, ActiveDeliveryState>(
      listener: (ctx, state) {
        if (state is ActiveDeliveryOtpReady) {
          setState(() {
            if (state.isPickup) {
              _pickupOtpGenerated = true;
            } else {
              _dropOtpGenerated = true;
            }
          });
        } else if (state is ActiveDeliveryOtpError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          // State badge
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _stateColor(delivery.state).withOpacity(0.15),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: _stateColor(delivery.state).withOpacity(0.4)),
              ),
              child: Text(
                delivery.state,
                style: TextStyle(
                  color: _stateColor(delivery.state),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Route card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _AddressRow(label: 'Pickup', address: delivery.pickupAddress, color: AppColors.success),
                Divider(color: AppColors.divider, height: 24.h),
                _AddressRow(label: 'Drop', address: delivery.dropAddress, color: AppColors.error),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Stats
          Row(
            children: [
              _InfoCard(label: 'Distance', value: '${delivery.distanceKm.toStringAsFixed(1)} km'),
              SizedBox(width: 12.w),
              _InfoCard(label: 'Fee', value: '₹${delivery.fee.toStringAsFixed(2)}'),
              SizedBox(width: 12.w),
              _InfoCard(label: 'Type', value: _typeLabel(delivery.deliveryType)),
            ],
          ),
          SizedBox(height: 32.h),

          // ── Pickup phase ────────────────────────────────────────────────
          if (isAssigned) ...[
            if (!_pickupOtpGenerated)
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Ready for Pickup'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => context.read<ActiveDeliveryCubit>().generatePickupOtp(
                      deliveryId: delivery.id,
                    ),
              )
            else ...[
              Text(
                'Enter Pickup OTP',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _pickupOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  hintStyle: TextStyle(
                      color: AppColors.divider,
                      fontSize: 28.sp,
                      letterSpacing: 12),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final otp = _pickupOtpController.text.trim();
                    if (otp.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter the 6-digit OTP.')),
                      );
                      return;
                    }
                    context.read<ActiveDeliveryCubit>().confirmPickup(
                          deliveryId: delivery.id,
                          otp: otp,
                        );
                  },
                  child: const Text('Confirm Pickup'),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () => context.read<ActiveDeliveryCubit>().resendPickupOtp(
                        deliveryId: delivery.id,
                      ),
                  child: Text('Resend OTP',
                      style: TextStyle(color: AppColors.accent, fontSize: 13.sp)),
                ),
              ),
            ],
          ],

          // ── Drop phase ──────────────────────────────────────────────────
          if (isInTransit) ...[
            if (!_dropOtpGenerated)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Ready to Deliver'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => context.read<ActiveDeliveryCubit>().generateDropOtp(
                      deliveryId: delivery.id,
                    ),
              )
            else ...[
              Text(
                'Enter Delivery OTP',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _dropOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  hintStyle: TextStyle(
                      color: AppColors.divider,
                      fontSize: 28.sp,
                      letterSpacing: 12),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () {
                    final otp = _dropOtpController.text.trim();
                    if (otp.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter the 6-digit OTP.')),
                      );
                      return;
                    }
                    context.read<ActiveDeliveryCubit>().confirmDelivery(
                          deliveryId: delivery.id,
                          otp: otp,
                        );
                  },
                  child: const Text('Confirm Delivery'),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () => context.read<ActiveDeliveryCubit>().resendDropOtp(
                        deliveryId: delivery.id,
                      ),
                  child: Text('Resend OTP',
                      style: TextStyle(color: AppColors.accent, fontSize: 13.sp)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'Assigned':   return AppColors.warning;
      case 'PickedUp':   return AppColors.primary;
      case 'InTransit':  return AppColors.accent;
      case 'Delivered':  return AppColors.success;
      case 'Cancelled':  return AppColors.error;
      default:           return AppColors.textSecondary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sosssss_3p':   return '3P';
      case 'seller':       return 'Seller';
      case 'buyer_pickup': return 'Pickup';
      default:             return type;
    }
  }
}

class _AddressRow extends StatelessWidget {
  final String label;
  final String address;
  final Color  color;
  const _AddressRow({required this.label, required this.address, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, color: color, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
              SizedBox(height: 2.h),
              Text(address, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
            SizedBox(height: 4.h),
            Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
