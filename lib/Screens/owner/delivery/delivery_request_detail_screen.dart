import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../Bloc/QuoteSubmit/quote_submit_cubit.dart';
import '../../../Model/delivery_request_model.dart';
import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';
import 'vehicle_picker_bottom_sheet.dart';

class DeliveryRequestDetailScreen extends StatefulWidget {
  final int requestId;

  const DeliveryRequestDetailScreen({super.key, required this.requestId});

  @override
  State<DeliveryRequestDetailScreen> createState() =>
      _DeliveryRequestDetailScreenState();
}

class _DeliveryRequestDetailScreenState
    extends State<DeliveryRequestDetailScreen> {
  DeliveryRequestModel? _request;
  bool _loading = true;
  String? _error;
  bool _vehiclesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final response =
          await ApiServiceUnified.instance.getDeliveryFeedDetail(widget.requestId);
      if (response['status'] == 'success') {
        setState(() {
          _request = DeliveryRequestModel.fromJson(
              response['data'] as Map<String, dynamic>);
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message'] as String? ?? 'Failed to load';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadVehiclesAndShowPicker() async {
    if (_vehiclesLoading) return;
    setState(() => _vehiclesLoading = true);
    try {
      final response =
          await ApiServiceUnified.instance.getQuoteVehicles(widget.requestId);
      if (!mounted) return;
      if (response['status'] == 'success') {
        final vehicles =
            (response['data'] as List? ?? []).cast<Map<String, dynamic>>();
        await VehiclePickerBottomSheet.show(context, widget.requestId, vehicles);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response['message'] as String? ?? 'Failed to load vehicles'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _vehiclesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return BlocProvider(
      create: (_) => QuoteSubmitCubit(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          foregroundColor: textPrimary,
          elevation: 0,
          title: Text(
            'Delivery Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: accentColor))
            : _error != null
                ? _ErrorBody(
                    error: _error!,
                    onRetry: _loadDetail,
                    isDark: isDark,
                  )
                : _buildBody(isDark),
        bottomNavigationBar: _request != null && _request!.status == 'open'
            ? _SendQuoteBar(
                loading: _vehiclesLoading,
                onTap: _loadVehiclesAndShowPicker,
                accentColor: accentColor,
              )
            : null,
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final req = _request!;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Map ─────────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: SizedBox(
              height: 220.h,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(req.pickupLat, req.pickupLng),
                  zoom: 10,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('pickup'),
                    position: LatLng(req.pickupLat, req.pickupLng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen),
                    infoWindow: const InfoWindow(title: 'Pickup'),
                  ),
                  Marker(
                    markerId: const MarkerId('drop'),
                    position: LatLng(req.dropLat, req.dropLng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                    infoWindow: const InfoWindow(title: 'Drop'),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // ── Stats row ────────────────────────────────────────────────────────
          Row(
            children: [
              _StatChip(
                text: '${req.distanceKm.toStringAsFixed(1)} km',
                icon: Icons.route_rounded,
                color: accentColor,
              ),
              SizedBox(width: 10.w),
              _StatChip(
                text: '~${req.estimatedDurationMin} min',
                icon: Icons.timer_rounded,
                color: isDark ? AppColors.warning : AppLightColors.warning,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Addresses ────────────────────────────────────────────────────────
          _AddressCard(
            label: 'Pickup',
            address: req.pickupAddress,
            color: AppColors.success,
            cardColor: cardColor,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 10.h),
          _AddressCard(
            label: 'Drop',
            address: req.dropAddress,
            color: isDark ? AppColors.error : AppLightColors.error,
            cardColor: cardColor,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 16.h),

          // ── Info rows ────────────────────────────────────────────────────────
          Divider(height: 1, thickness: 0.8, color: dividerColor),
          SizedBox(height: 12.h),
          _InfoRow(
            label: 'Type',
            value: req.requestType.replaceAll('_', ' ').toUpperCase(),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _InfoRow(
            label: 'Status',
            value: req.status.toUpperCase(),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            valueColor: req.status == 'open' ? AppColors.success : null,
          ),
          if (req.quotes.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              '${req.quotes.length} quote${req.quotes.length > 1 ? 's' : ''} submitted',
              style: TextStyle(fontSize: 12.sp, color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Send Quote bottom bar ────────────────────────────────────────────────────

class _SendQuoteBar extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final Color accentColor;

  const _SendQuoteBar({
    required this.loading,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: loading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accentColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: loading
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Send Quote',
                    style:
                        TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.r, color: color),
          SizedBox(width: 5.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final String label;
  final String address;
  final Color color;
  final Color cardColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  const _AddressCard({
    required this.label,
    required this.address,
    required this.color,
    required this.cardColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Icon(Icons.location_on_rounded, color: color, size: 16.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13.sp, color: textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorBody({
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = isDark ? AppColors.error : AppLightColors.error;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: errorColor, size: 28.r),
            ),
            SizedBox(height: 16.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13.sp),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
