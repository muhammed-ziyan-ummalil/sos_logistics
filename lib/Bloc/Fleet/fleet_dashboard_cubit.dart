import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'fleet_dashboard_state.dart';

class FleetDashboardCubit extends Cubit<FleetDashboardState> {
  FleetDashboardCubit() : super(FleetDashboardInitial());

  Future<void> fetchDashboard() async {
    emit(FleetDashboardLoading());

    // Core data — always available
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

    // Derive summary counts from driver list
    final totalDrivers = drivers.length;
    final activeDrivers =
        drivers.where((d) => d['status'] == 'active').length;
    final onlineDrivers = drivers.where((d) {
      final v = d['is_online'];
      return v == true || v == 1 || v == '1';
    }).length;

    // Alerts derived from driver list
    final inactiveAlerts = drivers
        .where((d) =>
            d['status'] == 'active' &&
            (d['last_online'] == null || _daysSince(d['last_online']) >= 3))
        .toList();

    final unassignedAlerts = drivers
        .where((d) =>
            d['status'] == 'active' && d['vehicle'] == null)
        .toList();

    // Optional: active deliveries
    List<Map<String, dynamic>> activeDeliveries = [];
    final deliveriesRes =
        await ApiServiceV2.instance.get('owner/deliveries/active');
    if (deliveriesRes['status'] == 'success') {
      final raw = (deliveriesRes['data']?['deliveries'] as List?) ?? [];
      activeDeliveries =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // Optional: today's earnings
    double? todayEarnings;
    final earningsRes =
        await ApiServiceV2.instance.get('owner/earnings/summary');
    if (earningsRes['status'] == 'success') {
      todayEarnings = double.tryParse(
              earningsRes['data']?['today']?.toString() ?? '');
    }

    // Optional: performance stats
    Map<String, dynamic> performance = {};
    final perfRes =
        await ApiServiceV2.instance.get('owner/performance');
    if (perfRes['status'] == 'success') {
      performance =
          Map<String, dynamic>.from(perfRes['data'] as Map? ?? {});
    } else {
      // Derive basic performance from driver data
      int totalCompleted = 0;
      int totalMissed = 0;
      int totalJobs = 0;
      for (final d in drivers) {
        final stats = d['performance'] as Map? ?? d['stats'] as Map? ?? {};
        totalCompleted +=
            (stats['completed_jobs'] as int? ?? 0);
        totalMissed += (stats['missed_jobs'] as int? ?? 0);
        totalJobs += (stats['total_jobs'] as int? ?? 0);
      }
      final rate = totalJobs > 0
          ? ((totalCompleted / totalJobs) * 100).clamp(0.0, 100.0)
          : 0.0;
      performance = {
        'acceptance_rate': rate,
        'missed_jobs': totalMissed,
        'completed_jobs': totalCompleted,
        'total_jobs': totalJobs,
      };
    }

    emit(FleetDashboardLoaded(
      summary: {
        'total_drivers': totalDrivers,
        'active_drivers': activeDrivers,
        'online_drivers': onlineDrivers,
        'active_deliveries': activeDeliveries.length,
        if (todayEarnings != null) 'today_earnings': todayEarnings,
      },
      drivers: drivers,
      activeDeliveries: activeDeliveries,
      performance: performance,
      inactiveAlerts: inactiveAlerts,
      unassignedAlerts: unassignedAlerts,
    ));
  }

  /// Returns days since [dateStr] (ISO 8601). Returns 0 on parse failure.
  int _daysSince(dynamic dateStr) {
    if (dateStr == null) return 0;
    final parsed = DateTime.tryParse(dateStr.toString());
    if (parsed == null) return 0;
    return DateTime.now().difference(parsed).inDays;
  }
}
