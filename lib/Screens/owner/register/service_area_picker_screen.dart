import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../widgets/widgets.dart';

/// Service-area picker for fleet-owner onboarding.
///
/// The owner taps the map to drop a marker on the centre of their service area.
/// Returns the picked LatLng to the caller (Navigator.pop). The backend stores it
/// as vehicle_owners.service_lat / service_lng and uses it to region-gate the
/// delivery feed + notifications (owners far from a pickup are not shown it).
///
/// Tap-to-pick uses google_maps_flutter's onTap (no GPS / geolocator dependency).
class ServiceAreaPickerScreen extends StatefulWidget {
  final LatLng? initial;

  const ServiceAreaPickerScreen({super.key, this.initial});

  @override
  State<ServiceAreaPickerScreen> createState() => _ServiceAreaPickerScreenState();
}

class _ServiceAreaPickerScreenState extends State<ServiceAreaPickerScreen> {
  // Default camera: geographic centre of India (used only until the owner taps).
  static const LatLng _indiaCenter = LatLng(22.5937, 78.9629);

  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = _picked ?? widget.initial ?? _indiaCenter;

    return Scaffold(
      appBar: const SosAppBar(title: 'Pick Your Service Area'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Text(
              'Tap the map to mark the centre of the area you deliver in. You will only be '
              'shown delivery requests near this point.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: start,
                zoom: _picked != null ? 12 : 4,
              ),
              onTap: (pos) => setState(() => _picked = pos),
              markers: _picked == null
                  ? <Marker>{}
                  : {
                      Marker(
                        markerId: const MarkerId('service_area'),
                        position: _picked!,
                      ),
                    },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_picked != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Text(
                        'Selected: ${_picked!.latitude.toStringAsFixed(5)}, '
                        '${_picked!.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                            ),
                      ),
                    ),
                  SosButton(
                    label: 'Confirm Service Area',
                    onPressed: _picked == null
                        ? null
                        : () => Navigator.of(context).pop(_picked),
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
