import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../Bloc/QuoteSubmit/quote_submit_cubit.dart';
import '../../../Model/delivery_request_model.dart';
import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';
import '../../../widgets/widgets.dart';
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
    return BlocProvider(
      create: (_) => QuoteSubmitCubit(),
      child: Scaffold(
        appBar: const SosAppBar(title: 'Delivery Details'),
        body: _loading
            ? _buildSkeleton()
            : _error != null
                ? ErrorState(
                    message: _error!,
                    onRetry: _loadDetail,
                  )
                : _buildBody(),
        bottomNavigationBar: _request != null && _request!.status == 'open'
            ? _SendQuoteBar(
                loading: _vehiclesLoading,
                onTap: _loadVehiclesAndShowPicker,
              )
            : null,
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: 220.h, radius: 14),
          SizedBox(height: 20.h),
          Row(children: [
            SkeletonBox(width: 100.w, height: 32.h),
            SizedBox(width: 10.w),
            SkeletonBox(width: 100.w, height: 32.h),
          ]),
          SizedBox(height: 16.h),
          SkeletonBox(width: double.infinity, height: 60.h),
          SizedBox(height: 10.h),
          SkeletonBox(width: double.infinity, height: 60.h),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final req = _request!;
    final scheme = Theme.of(context).colorScheme;

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
              SosChip(
                label: '${req.distanceKm.toStringAsFixed(1)} km',
                icon: Icons.route_rounded,
                tone: SosTone.success,
              ),
              SizedBox(width: 10.w),
              SosChip(
                label: '~${req.estimatedDurationMin} min',
                icon: Icons.timer_rounded,
                tone: SosTone.warning,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Addresses ────────────────────────────────────────────────────────
          _AddressCard(
            label: 'Pickup',
            address: req.pickupAddress,
            color: AppDesignTokens.success,
          ),
          SizedBox(height: 10.h),
          _AddressCard(
            label: 'Drop',
            address: req.dropAddress,
            color: scheme.error,
          ),
          SizedBox(height: 16.h),

          // ── Info rows ────────────────────────────────────────────────────────
          Divider(height: 1, thickness: 0.8, color: scheme.outline),
          SizedBox(height: 12.h),
          _InfoRow(
            label: 'Type',
            value: req.requestType.replaceAll('_', ' ').toUpperCase(),
          ),
          _InfoRow(
            label: 'Status',
            value: req.status.toUpperCase(),
            valueColor: req.status == 'open' ? AppDesignTokens.success : null,
          ),
          if (req.quotes.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              '${req.quotes.length} quote${req.quotes.length > 1 ? 's' : ''} submitted',
              style: TextStyle(
                  fontSize: 12.sp,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
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

  const _SendQuoteBar({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        child: SosButton(
          label: 'Send Quote',
          loading: loading,
          onPressed: loading ? null : onTap,
        ),
      ),
    );
  }
}

// ─── Address card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final String label;
  final String address;
  final Color color;

  const _AddressCard({
    required this.label,
    required this.address,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SosCard(
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
                    color: scheme.onSurface.withValues(alpha: 0.5),
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
                    color: scheme.onSurface,
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
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
                fontSize: 13.sp,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
