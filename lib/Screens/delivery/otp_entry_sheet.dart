import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../widgets/widgets.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
                color: scheme.outline,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            widget.isPickup ? 'Pickup OTP' : 'Delivery OTP',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 6.h),
          Text(
            widget.isPickup
                ? 'Ask the sender for the pickup OTP.'
                : 'Ask the recipient for the delivery OTP.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24.h),
          SosTextField(
            label: 'OTP',
            controller: _otpCtr,
            keyboardType: TextInputType.number,
            hint: '6-digit code',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          SizedBox(height: 24.h),
          SosButton(
            label: 'Verify OTP',
            onPressed: () => _submit(context),
          ),
        ],
      ),
    );
  }
}
