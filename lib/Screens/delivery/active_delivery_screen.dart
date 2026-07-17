import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Bloc/ActiveDelivery/active_delivery_cubit.dart';
import '../../Bloc/ActiveDelivery/active_delivery_state.dart';
import '../../Model/delivery_model.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../utility/api_service.dart';
import '../../widgets/widgets.dart';
import '../owner/delivery/report_issue_sheet.dart';

class DeliveryDetailView extends StatefulWidget {
  final ActiveDelivery delivery;
  final EdgeInsetsGeometry padding;
  const DeliveryDetailView({
    super.key,
    required this.delivery,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<DeliveryDetailView> createState() => _DeliveryDetailViewState();
}

class _DeliveryDetailViewState extends State<DeliveryDetailView> {
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
    final scheme      = Theme.of(context).colorScheme;

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
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
          );
        }
      },
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  lat: delivery.pickupLat,
                  lng: delivery.pickupLng,
                ),
                Divider(color: scheme.outline, height: 24.h),
                _AddressRow(
                  label: 'Drop',
                  address: delivery.dropAddress,
                  color: scheme.error,
                  lat: delivery.dropLat,
                  lng: delivery.dropLng,
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

          // ── Batch / stock timing ────────────────────────────────────────
          if (delivery.pickupWindow.isNotEmpty ||
              delivery.dropWindow.isNotEmpty ||
              delivery.stockFromDate.isNotEmpty ||
              delivery.stockToDate.isNotEmpty) ...[
            SizedBox(height: 16.h),
            SosCard(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimingRow(
                    icon: Icons.inventory_2_outlined,
                    color: AppDesignTokens.success,
                    label: 'Pickup',
                    value: [
                      if (delivery.stockFromDate.isNotEmpty ||
                          delivery.stockToDate.isNotEmpty)
                        '${delivery.stockFromDate} to ${delivery.stockToDate}',
                      if (delivery.pickupWindow.isNotEmpty)
                        delivery.pickupWindow,
                    ].join('  ·  '),
                  ),
                  SizedBox(height: 10.h),
                  _TimingRow(
                    icon: Icons.local_shipping_outlined,
                    color: scheme.error,
                    label: 'Deliver by',
                    value: [
                      if (delivery.stockToDate.isNotEmpty)
                        delivery.stockToDate,
                      if (delivery.dropWindow.isNotEmpty) delivery.dropWindow,
                    ].join('  ·  '),
                  ),
                ],
              ),
            ),
          ],
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

          // ── Report an issue (available on any active delivery) ────────────
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ReportIssueSheet.show(
                context,
                (t, d) => ApiServiceUnified.instance.reportDriverDeliveryIssue(
                  deliveryId: delivery.id,
                  issueType: t,
                  description: d,
                ),
              ),
              icon: Icon(Icons.report_gmailerrorred_outlined, size: 18.r),
              label: const Text('Report an issue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          ],
        ),
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
  final String  label;
  final String  address;
  final Color   color;
  final String? lat;
  final String? lng;
  const _AddressRow({
    required this.label,
    required this.address,
    required this.color,
    this.lat,
    this.lng,
  });

  /// Build a Google Maps directions link — turn-by-turn from the driver's
  /// current location. Prefers precise coordinates; falls back to the address
  /// text. Universal URL opens the Maps app (Android/iOS) or a browser.
  Uri? _mapsUri() {
    final la = double.tryParse(lat ?? '');
    final ln = double.tryParse(lng ?? '');
    if (la != null && ln != null && !(la == 0 && ln == 0)) {
      return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$la,$ln');
    }
    if (address.trim().isNotEmpty) {
      final q = Uri.encodeComponent(address.trim());
      return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q');
    }
    return null;
  }

  Future<void> _navigate(BuildContext context) async {
    final uri = _mapsUri();
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme      = Theme.of(context).colorScheme;
    final hasMap      = _mapsUri() != null;

    return InkWell(
      onTap: hasMap ? () => _navigate(context) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
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
            if (hasMap) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_rounded, color: color, size: 15.r),
                    SizedBox(width: 4.w),
                    Text(
                      'Directions',
                      style: TextStyle(
                        color: color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  const _TimingRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11.sp)),
              SizedBox(height: 2.h),
              Text(value, style: TextStyle(color: scheme.onSurface, fontSize: 13.sp)),
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
