import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Bloc/Fleet/fleet_dashboard_cubit.dart';
import '../../Bloc/Fleet/fleet_dashboard_state.dart';
import '../../Bloc/OwnerVehicles/owner_vehicles_cubit.dart';
import '../../Bloc/OwnerVehicles/owner_vehicles_state.dart';
import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../widgets/widgets.dart';

class OwnerManageScreen extends StatefulWidget {
  const OwnerManageScreen({super.key});

  @override
  State<OwnerManageScreen> createState() => _OwnerManageScreenState();
}

class _OwnerManageScreenState extends State<OwnerManageScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh vehicles count whenever Manage tab is opened
    context.read<OwnerVehiclesCubit>().fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SosAppBar(title: 'Manage'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const _DriversManageCard(),
            const SizedBox(height: 16),
            const _VehiclesManageCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ─── Drivers Manage Card ──────────────────────────────────────────────────────

class _DriversManageCard extends StatelessWidget {
  const _DriversManageCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return SosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusXS),
                  ),
                  child: Icon(Icons.people_rounded, color: primary, size: AppDesignTokens.iconSizeS),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Drivers', style: Theme.of(context).textTheme.labelLarge),
                      Text('Manage your driver fleet',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats from FleetDashboardCubit
          BlocBuilder<FleetDashboardCubit, FleetDashboardState>(
            builder: (_, state) {
              int total = 0, active = 0, online = 0;
              if (state is FleetDashboardLoaded) {
                total = state.drivers.length;
                active = state.drivers.where((d) => d['status'] == 'active').length;
                online = state.drivers.where((d) {
                  final v = d['is_online'];
                  return v == true || v == 1 || v == '1';
                }).length;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.people_outline_rounded,
                        label: 'Total',
                        value: total.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Active',
                        value: active.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        icon: Icons.wifi_rounded,
                        label: 'Online',
                        value: online.toString(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          const Divider(),
          const SizedBox(height: 12),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SosButton(
                    label: 'All Drivers',
                    icon: Icons.list_rounded,
                    fullWidth: true,
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.v2DriverList),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SosButton(
                    label: 'Add Driver',
                    icon: Icons.person_add_rounded,
                    variant: SosButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () async {
                      final added = await Navigator.pushNamed(
                          context, AppRoutes.v2AddDriver);
                      if (added == true && context.mounted) {
                        context.read<FleetDashboardCubit>().fetchDashboard();
                      }
                    },
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

// ─── Vehicles Manage Card ─────────────────────────────────────────────────────

class _VehiclesManageCard extends StatelessWidget {
  const _VehiclesManageCard();

  @override
  Widget build(BuildContext context) {
    final warningColor = AppTheme.warning(context);

    return SosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusXS),
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: warningColor, size: AppDesignTokens.iconSizeS),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicles', style: Theme.of(context).textTheme.labelLarge),
                      Text('Track and assign your vehicles',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats from OwnerVehiclesCubit
          BlocBuilder<OwnerVehiclesCubit, OwnerVehiclesState>(
            builder: (_, state) {
              int total = 0, assigned = 0, available = 0;
              if (state is OwnerVehiclesLoaded) {
                total = state.vehicles.length;
                assigned = state.vehicles
                    .where((v) =>
                        v['assigned_driver'] != null ||
                        v['assigned_driver_id'] != null)
                    .length;
                // Available = approved (active) AND unassigned. A pending vehicle
                // is not available until an admin approves it.
                available = state.vehicles.where((v) {
                  final st = (v['status'] as String?)?.toLowerCase();
                  final isAssigned = v['assigned_driver'] != null ||
                      v['assigned_driver_id'] != null;
                  return st == 'active' && !isAssigned;
                }).length;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.directions_car_outlined,
                        label: 'Total',
                        value: total.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        icon: Icons.link_rounded,
                        label: 'Assigned',
                        value: assigned.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        icon: Icons.check_rounded,
                        label: 'Available',
                        value: available.toString(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          const Divider(),
          const SizedBox(height: 12),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SosButton(
                    label: 'All Vehicles',
                    icon: Icons.list_rounded,
                    fullWidth: true,
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.v2VehicleList),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SosButton(
                    label: 'Add Vehicle',
                    icon: Icons.add_rounded,
                    variant: SosButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.v2VehicleList,
                      arguments: {'openAdd': true},
                    ),
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
