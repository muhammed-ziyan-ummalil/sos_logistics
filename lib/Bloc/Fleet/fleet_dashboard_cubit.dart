import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'fleet_dashboard_state.dart';

class FleetDashboardCubit extends Cubit<FleetDashboardState> {
  FleetDashboardCubit() : super(FleetDashboardInitial());

  Future<void> fetchDashboard() async {
    emit(FleetDashboardLoading());

    // ── Core — required ───────────────────────────────────────────────────────
    // listDrivers() returns enriched data: vehicle, performance, is_online
    final driversRes = await ApiServiceV2.instance.get('owner/drivers');
    if (driversRes['status'] != 'success') {
      emit(FleetDashboardError(
          driversRes['message'] as String? ?? 'Failed to load fleet data.'));
      return;
    }

    final rawDrivers = (driversRes['data']?['drivers'] as List?) ?? [];
    final drivers = rawDrivers
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Summary counts derived from enriched driver list
    final totalDrivers  = drivers.length;
    final activeDrivers = drivers.where((d) => d['status'] == 'active').length;
    final onlineDrivers = drivers.where((d) {
      final v = d['is_online'];
      return v == true || v == 1 || v == '1';
    }).length;

    // ── Alerts — backend-computed; no client-side logic ───────────────────────
    List<Map<String, dynamic>> inactiveAlerts   = [];
    List<Map<String, dynamic>> unassignedAlerts = [];
    final alertsRes = await ApiServiceV2.instance.get('owner/fleet/alerts');
    if (alertsRes['status'] == 'success') {
      final alertData     = alertsRes['data'] as Map<String, dynamic>? ?? {};
      final inactiveRaw   = alertData['inactive_drivers']   as List? ?? [];
      final unassignedRaw = alertData['unassigned_drivers'] as List? ?? [];
      inactiveAlerts = inactiveRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      unassignedAlerts = unassignedRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // ── Optional: active deliveries ───────────────────────────────────────────
    List<Map<String, dynamic>> activeDeliveries = [];
    final deliveriesRes =
        await ApiServiceV2.instance.get('owner/deliveries/active');
    if (deliveriesRes['status'] == 'success') {
      final raw = (deliveriesRes['data']?['deliveries'] as List?) ?? [];
      activeDeliveries =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // ── Optional: today's earnings ────────────────────────────────────────────
    double? todayEarnings;
    final earningsRes =
        await ApiServiceV2.instance.get('owner/earnings/summary');
    if (earningsRes['status'] == 'success') {
      todayEarnings = double.tryParse(
          earningsRes['data']?['today']?.toString() ?? '');
    }

    // ── Optional: fleet performance ───────────────────────────────────────────
    // Primary: dedicated endpoint. Fallback: aggregate from enriched driver list.
    Map<String, dynamic> performance = {};
    final perfRes = await ApiServiceV2.instance.get('owner/performance');
    if (perfRes['status'] == 'success') {
      performance =
          Map<String, dynamic>.from(perfRes['data'] as Map? ?? {});
    } else {
      int totalCompleted = 0;
      int totalMissed    = 0;
      int totalJobs      = 0;
      for (final d in drivers) {
        final stats = d['performance'] as Map? ?? {};
        totalCompleted += ((stats['completed_jobs'] as num?)?.toInt() ?? 0);
        totalMissed    += ((stats['missed_jobs']    as num?)?.toInt() ?? 0);
        totalJobs      += ((stats['total_jobs']     as num?)?.toInt() ?? 0);
      }
      final rate = totalJobs > 0
          ? ((totalCompleted / totalJobs) * 100).clamp(0.0, 100.0)
          : 0.0;
      performance = {
        'acceptance_rate': rate,
        'missed_jobs':     totalMissed,
        'completed_jobs':  totalCompleted,
        'total_jobs':      totalJobs,
      };
    }

    emit(FleetDashboardLoaded(
      summary: {
        'total_drivers':     totalDrivers,
        'active_drivers':    activeDrivers,
        'online_drivers':    onlineDrivers,
        'active_deliveries': activeDeliveries.length,
        if (todayEarnings != null) 'today_earnings': todayEarnings,
      },
      drivers:          drivers,
      activeDeliveries: activeDeliveries,
      performance:      performance,
      inactiveAlerts:   inactiveAlerts,
      unassignedAlerts: unassignedAlerts,
    ));
  }
}
