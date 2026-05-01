import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Model/delivery_model.dart';
import '../../core/app_theme.dart';

class OfferCard extends StatelessWidget {
  final DeliveryOffer offer;
  final VoidCallback   onAccept;
  final VoidCallback   onReject;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 18.r),
                ),
                SizedBox(width: 10.w),
                Text(
                  'New Delivery Offer',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Expires soon',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                // Route
                _RouteRow(
                  from: offer.pickupAddress,
                  to:   offer.dropAddress,
                ),
                SizedBox(height: 16.h),

                // Stats row
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.route_rounded,
                      label: '${offer.distanceKm.toStringAsFixed(1)} km',
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10.w),
                    _StatChip(
                      icon: Icons.currency_rupee_rounded,
                      label: '₹${offer.fee.toStringAsFixed(2)}',
                      color: AppColors.success,
                    ),
                    SizedBox(width: 10.w),
                    _StatChip(
                      icon: Icons.local_shipping_outlined,
                      label: _typeLabel(offer.deliveryType),
                      color: AppColors.warning,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error.withOpacity(0.6)),
                          foregroundColor: AppColors.error,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Decline', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        child: Text('Accept Delivery', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sosssss_3p':    return '3P';
      case 'seller':        return 'Seller';
      case 'buyer_pickup':  return 'Pickup';
      default:              return type;
    }
  }
}

class _RouteRow extends StatelessWidget {
  final String from;
  final String to;
  const _RouteRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(Icons.circle, color: AppColors.success, size: 10.r),
            Container(width: 2.w, height: 32.h, color: AppColors.divider),
            Icon(Icons.location_on, color: AppColors.error, size: 14.r),
          ],
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 16.h),
              Text(to, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14.r),
            SizedBox(width: 4.w),
            Text(label, style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
