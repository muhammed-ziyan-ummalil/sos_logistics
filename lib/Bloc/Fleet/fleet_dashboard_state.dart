abstract class FleetDashboardState {}

class FleetDashboardInitial extends FleetDashboardState {}

class FleetDashboardLoading extends FleetDashboardState {}

class FleetDashboardLoaded extends FleetDashboardState {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> activeDeliveries;
  final Map<String, dynamic> performance;
  final List<Map<String, dynamic>> inactiveAlerts;
  final List<Map<String, dynamic>> unassignedAlerts;

  FleetDashboardLoaded({
    required this.summary,
    required this.drivers,
    required this.activeDeliveries,
    required this.performance,
    required this.inactiveAlerts,
    required this.unassignedAlerts,
  });
}

class FleetDashboardError extends FleetDashboardState {
  final String message;
  FleetDashboardError(this.message);
}
