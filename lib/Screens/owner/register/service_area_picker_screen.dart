import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../widgets/widgets.dart';

/// Result of the service-area picker: the centre point plus the serving radius.
class ServiceAreaResult {
  final LatLng center;
  final double radiusKm;

  const ServiceAreaResult({required this.center, required this.radiusKm});
}

/// Service-area picker for fleet-owner onboarding.
///
/// The owner taps the map (or uses their current location) to drop a marker on
/// the centre of their service area, then sets how far out they will serve with
/// a radius slider. A translucent emerald circle previews the coverage live.
///
/// Returns a [ServiceAreaResult] (centre LatLng + radiusKm) to the caller via
/// Navigator.pop. The backend stores the centre as vehicle_owners.service_lat /
/// service_lng and the radius as service_radius_km, and uses them to region-gate
/// the delivery feed + notifications (owners far from a pickup are not shown it).
class ServiceAreaPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final double? initialRadiusKm;

  const ServiceAreaPickerScreen({super.key, this.initial, this.initialRadiusKm});

  @override
  State<ServiceAreaPickerScreen> createState() => _ServiceAreaPickerScreenState();
}

class _ServiceAreaPickerScreenState extends State<ServiceAreaPickerScreen> {
  // Default camera: geographic centre of India (used only until a point is set).
  static const LatLng _indiaCenter = LatLng(22.5937, 78.9629);

  static const double _minRadiusKm = 5;
  static const double _maxRadiusKm = 100;
  static const double _defaultRadiusKm = 10;

  LatLng? _picked;
  double _radiusKm = _defaultRadiusKm;
  bool _locating = false;
  GoogleMapController? _mapController;
  late final TextEditingController _radiusCtrl;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
    final r = widget.initialRadiusKm ?? _defaultRadiusKm;
    _radiusKm = r.clamp(_minRadiusKm, _maxRadiusKm).toDouble();
    _radiusCtrl = TextEditingController(text: _radiusKm.round().toString());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  /// Apply a typed radius: parse, clamp to [min,max], sync slider + circle.
  void _commitTypedRadius() {
    final v = double.tryParse(_radiusCtrl.text.trim());
    if (v != null) {
      setState(() => _radiusKm = v.clamp(_minRadiusKm, _maxRadiusKm).toDouble());
    }
    _radiusCtrl.text = _radiusKm.round().toString();
  }

  void _setPoint(LatLng pos, {bool animate = false}) {
    setState(() => _picked = pos);
    if (animate) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 11));
    }
  }

  /// Requests permission, reads the device position, and drops the marker there.
  /// Degrades gracefully: services-off or denied just shows a snackbar and the
  /// owner can still tap-to-pick.
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Location services are off. Tap the map to pick instead.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _snack('Location permission denied. Tap the map to pick instead.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('Location permission is permanently denied. '
            'Enable it in Settings, or tap the map to pick.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _setPoint(LatLng(pos.latitude, pos.longitude), animate: true);
    } catch (_) {
      _snack('Could not get your location. Tap the map to pick instead.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    final start  = _picked ?? widget.initial ?? _indiaCenter;
    final hasPoint = _picked != null;

    return Scaffold(
      appBar: const SosAppBar(title: 'Pick Your Service Area'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
            child: Text(
              'Tap the map to mark the centre of the area you deliver in, then set '
              'how far out you will serve. You will only be shown delivery requests '
              'inside this circle.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => _mapController = c,
                  initialCameraPosition: CameraPosition(
                    target: start,
                    zoom: hasPoint ? 11 : 4,
                  ),
                  onTap: (pos) => _setPoint(pos),
                  markers: !hasPoint
                      ? <Marker>{}
                      : {
                          Marker(
                            markerId: const MarkerId('service_area'),
                            position: _picked!,
                          ),
                        },
                  circles: !hasPoint
                      ? <Circle>{}
                      : {
                          Circle(
                            circleId: const CircleId('service_radius'),
                            center: _picked!,
                            radius: _radiusKm * 1000, // km -> metres
                            fillColor: scheme.primary.withValues(alpha: 0.15),
                            strokeColor: scheme.primary.withValues(alpha: 0.9),
                            strokeWidth: 2,
                          ),
                        },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
                // "Use my current location" pill - top-right over the map.
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: _CurrentLocationButton(
                    loading: _locating,
                    onTap: _useCurrentLocation,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service radius slider - live value + circle update.
                  Row(
                    children: [
                      Icon(Icons.radar_outlined, size: 18.sp, color: scheme.primary),
                      SizedBox(width: 8.w),
                      Text(
                        'Service radius',
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 64.w,
                        child: TextField(
                          controller: _radiusCtrl,
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onTapOutside: (_) {
                            FocusScope.of(context).unfocus();
                            _commitTypedRadius();
                          },
                          onSubmitted: (_) => _commitTypedRadius(),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text('km',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: scheme.primary)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: scheme.outline,
                      thumbColor: scheme.primary,
                      overlayColor: scheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      min: _minRadiusKm,
                      max: _maxRadiusKm,
                      divisions: 19, // 5 km steps across 5..100
                      value: _radiusKm,
                      label: '${_radiusKm.round()} km',
                      onChanged: (v) => setState(() {
                        _radiusKm = v;
                        _radiusCtrl.text = v.round().toString();
                      }),
                    ),
                  ),
                  if (hasPoint)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Text(
                        'Centre: ${_picked!.latitude.toStringAsFixed(5)}, '
                        '${_picked!.longitude.toStringAsFixed(5)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Text(
                        'Tap the map to set your centre point.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  SosButton(
                    label: 'Confirm Service Area',
                    onPressed: !hasPoint
                        ? null
                        : () => Navigator.of(context).pop(
                              ServiceAreaResult(
                                center: _picked!,
                                radiusKm: _radiusKm,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact emerald "Use my current location" pill that floats over the map.
class _CurrentLocationButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _CurrentLocationButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(Icons.my_location, size: 18.sp, color: scheme.primary),
              SizedBox(width: 8.w),
              Text(
                'Use my location',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
