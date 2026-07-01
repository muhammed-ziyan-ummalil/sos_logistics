import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../Model/delivery_model.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../widgets/widgets.dart';

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
              backgroundColor: AppTheme.success(ctx),
            ),
          );
          Navigator.pop(ctx);
        } else if (state is ActiveDeliveryOtpError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const SosAppBar(title: 'Active Delivery'),
        body: BlocBuilder<ActiveDeliveryCubit, ActiveDeliveryState>(
          builder: (ctx, state) {
            if (state is ActiveDeliveryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ActiveDeliveryNone) {
              return const EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No active delivery',
                subtitle: 'Accepted jobs will appear here.',
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
  // TODO(TESTING): plaintext OTP shown/auto-filled while SMS/email is pending.
  String? _pickupTestOtp;
  String? _dropTestOtp;
  final _pickupOtpController = TextEditingController();
  final _dropOtpController   = TextEditingController();

  @override
  void dispose() {
    _pickupOtpController.dispose();
    _dropOtpController.dispose();
    super.dispose();
  }

  // TODO(TESTING): shows + auto-fills the plaintext OTP while SMS/email delivery
  // is pending. Remove once real OTP delivery is live.
  Widget _testOtpBanner(String otp) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16.r, color: Colors.orange.shade800),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'TEST MODE - OTP: $otp (auto-filled; SMS/email pending)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivery    = widget.delivery;
    final isAssigned  = delivery.state == 'Assigned';
    final isInTransit = delivery.state == 'InTransit' || delivery.state == 'PickedUp';
    final scheme      = Theme.of(context).colorScheme;

    return BlocListener<ActiveDeliveryCubit, ActiveDeliveryState>(
      listener: (ctx, state) {
        if (state is ActiveDeliveryOtpReady) {
          setState(() {
            if (state.isPickup) {
              _pickupOtpGenerated = true;
              _pickupTestOtp = state.testOtp;
              if (state.testOtp != null && state.testOtp!.isNotEmpty) {
                _pickupOtpController.text = state.testOtp!;
              }
            } else {
              _dropOtpGenerated = true;
              _dropTestOtp = state.testOtp;
              if (state.testOtp != null && state.testOtp!.isNotEmpty) {
                _dropOtpController.text = state.testOtp!;
              }
            }
          });
        } else if (state is ActiveDeliveryOtpError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
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
                color: _stateColor(context, delivery.state).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: _stateColor(context, delivery.state).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                delivery.state,
                style: TextStyle(
                  color: _stateColor(context, delivery.state),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Route card
          SosCard(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                _AddressRow(
                  label: 'Pickup',
                  address: delivery.pickupAddress,
                  color: AppDesignTokens.success,
                ),
                Divider(color: scheme.outline, height: 24.h),
                _AddressRow(
                  label: 'Drop',
                  address: delivery.dropAddress,
                  color: scheme.error,
                ),
                if ((delivery.dropContactName?.isNotEmpty ?? false) ||
                    (delivery.dropContactPhone?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.person_pin_circle_outlined,
                          size: 16.r, color: scheme.error),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          [
                            if (delivery.dropContactName?.isNotEmpty ?? false)
                              delivery.dropContactName!,
                            if (delivery.dropContactPhone?.isNotEmpty ?? false)
                              delivery.dropContactPhone!,
                          ].join('  ·  '),
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Stats
          Row(
            children: [
              _InfoCard(label: 'Distance', value: '${delivery.distanceKm.toStringAsFixed(1)} km'),
              SizedBox(width: 12.w),
              _InfoCard(
                label: 'Fee',
                value: '${AppConstants.currencySymbol}${delivery.fee.toStringAsFixed(2)}',
              ),
              SizedBox(width: 12.w),
              _InfoCard(label: 'Type', value: _typeLabel(delivery.deliveryType)),
            ],
          ),
          SizedBox(height: 32.h),

          // ── Pickup phase ────────────────────────────────────────────────
          if (isAssigned) ...[
            if (!_pickupOtpGenerated)
              SosButton(
                label: 'Ready for Pickup',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () => context.read<ActiveDeliveryCubit>().generatePickupOtp(
                      deliveryId: delivery.id,
                    ),
              )
            else ...[
              Text(
                'Enter Pickup OTP',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              if (_pickupTestOtp != null && _pickupTestOtp!.isNotEmpty) ...[
                _testOtpBanner(_pickupTestOtp!),
                SizedBox(height: 8.h),
              ],
              TextField(
                controller: _pickupOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  hintStyle: TextStyle(fontSize: 28.sp, letterSpacing: 12),
                ),
              ),
              SizedBox(height: 12.h),
              SosButton(
                label: 'Confirm Pickup',
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
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () => context.read<ActiveDeliveryCubit>().resendPickupOtp(
                        deliveryId: delivery.id,
                      ),
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: AppTheme.accent(context), fontSize: 13.sp),
                  ),
                ),
              ),
            ],
          ],

          // ── Drop phase ──────────────────────────────────────────────────
          if (isInTransit) ...[
            if (!_dropOtpGenerated)
              SosButton(
                label: 'Ready to Deliver',
                icon: Icons.check_circle_rounded,
                onPressed: () => context.read<ActiveDeliveryCubit>().generateDropOtp(
                      deliveryId: delivery.id,
                    ),
              )
            else ...[
              Text(
                'Enter Delivery OTP',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              if (_dropTestOtp != null && _dropTestOtp!.isNotEmpty) ...[
                _testOtpBanner(_dropTestOtp!),
                SizedBox(height: 8.h),
              ],
              TextField(
                controller: _dropOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  hintStyle: TextStyle(fontSize: 28.sp, letterSpacing: 12),
                ),
              ),
              SizedBox(height: 12.h),
              SosButton(
                label: 'Confirm Delivery',
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
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () => context.read<ActiveDeliveryCubit>().resendDropOtp(
                        deliveryId: delivery.id,
                      ),
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: AppTheme.accent(context), fontSize: 13.sp),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _stateColor(BuildContext context, String state) {
    final scheme = Theme.of(context).colorScheme;
    switch (state) {
      case 'Assigned':   return AppDesignTokens.warning;
      case 'PickedUp':   return scheme.primary;
      case 'InTransit':  return scheme.secondary;
      case 'Delivered':  return AppDesignTokens.success;
      case 'Cancelled':  return scheme.error;
      default:           return AppTheme.textSecondary(context);
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, color: color, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11.sp)),
              SizedBox(height: 2.h),
              Text(address, style: TextStyle(color: scheme.onSurface, fontSize: 13.sp)),
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
      child: SosCard(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11.sp)),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
