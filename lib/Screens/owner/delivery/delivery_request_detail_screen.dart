import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../Bloc/QuoteSubmit/quote_submit_cubit.dart';
import '../../../Bloc/QuoteSubmit/quote_submit_state.dart';
import '../../../Model/delivery_request_model.dart';
import '../../../core/app_constants.dart';
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

  // Inline shipping estimate (own vehicles + calculated fee) shown on the detail
  // screen so the owner sees the payout before opening the Send Quote picker.
  List<Map<String, dynamic>> _vehicles = [];
  bool _feeLoading = false;
  String? _feeError;

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
        if (_request?.status == 'open') _loadFees();
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
        // Refresh after the picker closes so a just-submitted quote flips the
        // screen out of the 'open' state (belt-and-suspenders with the listener).
        if (mounted) _loadDetail();
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

  // Load own vehicles + their calculated fee for this request (same endpoint the
  // Send Quote picker uses) so the fee summary shows inline.
  Future<void> _loadFees() async {
    setState(() {
      _feeLoading = true;
      _feeError = null;
    });
    try {
      final response =
          await ApiServiceUnified.instance.getQuoteVehicles(widget.requestId);
      if (!mounted) return;
      if (response['status'] == 'success') {
        setState(() {
          _vehicles =
              (response['data'] as List? ?? []).cast<Map<String, dynamic>>();
          _feeLoading = false;
        });
      } else {
        setState(() {
          _feeError =
              response['message'] as String? ?? 'Could not load estimate';
          _feeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feeError = e.toString();
          _feeLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuoteSubmitCubit(),
      child: BlocListener<QuoteSubmitCubit, QuoteSubmitState>(
        listener: (context, state) {
          if (state is QuoteSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quote submitted.')),
            );
            // Refresh so the screen reflects the new 'quoted' state (hides the
            // Send Quote bar + estimate, shows the submitted quote).
            _loadDetail();
          }
        },
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
          if (req.status == 'open') ...[
            SizedBox(height: 16.h),
            _ShippingEstimateCard(
              loading: _feeLoading,
              error: _feeError,
              vehicles: _vehicles,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shipping estimate (own vehicles + calculated fee) ────────────────────────

class _ShippingEstimateCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> vehicles;

  const _ShippingEstimateCard({
    required this.loading,
    required this.error,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SosCard(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 16.r, color: AppDesignTokens.success),
              SizedBox(width: 8.w),
              Text(
                'Shipping Estimate',
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: const Center(
                  child: SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (error != null)
            Text(
              error!,
              style: TextStyle(fontSize: 12.sp, color: scheme.error),
            )
          else if (vehicles.isEmpty)
            Text(
              'No eligible vehicle for this delivery.',
              style: TextStyle(
                  fontSize: 12.sp,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            )
          else
            ...vehicles.map((v) => _vehicleRow(context, v)),
          if (!loading && error == null && vehicles.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'Tap Send Quote to pick a vehicle and confirm.',
              style: TextStyle(
                  fontSize: 10.sp,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vehicleRow(BuildContext context, Map<String, dynamic> v) {
    final scheme = Theme.of(context).colorScheme;
    final fee = v['fee_breakdown'] as Map<String, dynamic>? ?? {};
    final total = double.tryParse('${fee['total_fee'] ?? 0}') ?? 0;
    final base = double.tryParse('${fee['base_fee'] ?? 0}') ?? 0;
    final extra = double.tryParse('${fee['extra_km_charge'] ?? 0}') ?? 0;
    final reg = (v['registration_number'] ?? v['driver_name'] ?? 'Vehicle')
        .toString();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reg,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface),
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${total.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppDesignTokens.success),
              ),
            ],
          ),
          Text(
            'Base ${AppConstants.currencySymbol}${base.toStringAsFixed(0)}'
            '${extra > 0 ? ' + extra km ${AppConstants.currencySymbol}${extra.toStringAsFixed(0)}' : ''}',
            style: TextStyle(
                fontSize: 10.sp,
                color: scheme.onSurface.withValues(alpha: 0.55)),
          ),
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
