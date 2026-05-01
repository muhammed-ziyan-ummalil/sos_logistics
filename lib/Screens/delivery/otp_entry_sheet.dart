import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../core/app_theme.dart';

class OtpEntrySheet extends StatefulWidget {
  final int  deliveryId;
  final bool isPickup;

  const OtpEntrySheet({super.key, required this.deliveryId, required this.isPickup});

  @override
  State<OtpEntrySheet> createState() => _OtpEntrySheetState();
}

class _OtpEntrySheetState extends State<OtpEntrySheet> {
  final _otpCtr = TextEditingController();

  @override
  void dispose() {
    _otpCtr.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    final otp = _otpCtr.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP.')),
      );
      return;
    }
    if (widget.isPickup) {
      ctx.read<ActiveDeliveryCubit>().confirmPickup(
        deliveryId: widget.deliveryId,
        otp: otp,
      );
    } else {
      ctx.read<ActiveDeliveryCubit>().confirmDelivery(
        deliveryId: widget.deliveryId,
        otp: otp,
      );
    }
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            widget.isPickup ? 'Pickup OTP' : 'Delivery OTP',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.isPickup
                ? 'Ask the sender for the pickup OTP.'
                : 'Ask the recipient for the delivery OTP.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 24.h),
          TextField(
            controller: _otpCtr,
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
              hintStyle: TextStyle(color: AppColors.divider, fontSize: 28.sp, letterSpacing: 12),
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPickup ? AppColors.primary : AppColors.success,
              ),
              child: Text(widget.isPickup ? 'Confirm Pickup' : 'Confirm Delivery'),
            ),
          ),
        ],
      ),
    );
  }
}
