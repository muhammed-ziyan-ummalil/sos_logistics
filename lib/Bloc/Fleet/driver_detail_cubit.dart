import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'driver_detail_state.dart';

class DriverDetailCubit extends Cubit<DriverDetailState> {
  DriverDetailCubit() : super(DriverDetailInitial());

  Future<void> fetchDriver(String driverId) async {
    emit(DriverDetailLoading());
    final res = await ApiServiceV2.instance.get('owner/drivers/$driverId');
    if (res['status'] == 'success') {
      final d = Map<String, dynamic>.from(
          (res['data']?['driver'] ?? res['data']) as Map? ?? {});
      emit(DriverDetailLoaded(d));
    } else {
      emit(DriverDetailError(
          res['message'] as String? ?? 'Failed to load driver.'));
    }
  }

  Future<void> setStatus(String driverId, String newStatus) async {
    final current = _current;
    if (current == null) return;
    emit(DriverDetailActionLoading(current));
    final res = await ApiServiceV2.instance
        .post('owner/drivers/$driverId/status', data: {'status': newStatus});
    if (res['status'] == 'success') {
      final updated = Map<String, dynamic>.from(current)
        ..['status'] = newStatus;
      emit(DriverDetailActionSuccess(
          driver: updated, message: 'Driver status updated.'));
      emit(DriverDetailLoaded(updated));
    } else {
      emit(DriverDetailActionError(
          driver: current,
          message: res['message'] as String? ?? 'Failed to update status.'));
      emit(DriverDetailLoaded(current));
    }
  }

  Future<void> assignVehicle(String driverId, String vehicleId) async {
    final current = _current;
    if (current == null) return;
    emit(DriverDetailActionLoading(current));
    final res = await ApiServiceV2.instance.post(
        'owner/drivers/$driverId/assign-vehicle',
        data: {'vehicle_id': vehicleId});
    if (res['status'] == 'success') {
      emit(DriverDetailActionSuccess(
          driver: current, message: 'Vehicle assigned.'));
      await fetchDriver(driverId);
    } else {
      emit(DriverDetailActionError(
          driver: current,
          message: res['message'] as String? ?? 'Failed to assign vehicle.'));
      emit(DriverDetailLoaded(current));
    }
  }

  Future<void> removeVehicle(String driverId) async {
    final current = _current;
    if (current == null) return;
    emit(DriverDetailActionLoading(current));
    final res = await ApiServiceV2.instance
        .post('owner/drivers/$driverId/remove-vehicle', data: {});
    if (res['status'] == 'success') {
      emit(DriverDetailActionSuccess(
          driver: current, message: 'Vehicle removed.'));
      await fetchDriver(driverId);
    } else {
      emit(DriverDetailActionError(
          driver: current,
          message: res['message'] as String? ?? 'Failed to remove vehicle.'));
      emit(DriverDetailLoaded(current));
    }
  }

  Map<String, dynamic>? get _current {
    final s = state;
    if (s is DriverDetailLoaded) return s.driver;
    if (s is DriverDetailActionLoading) return s.driver;
    if (s is DriverDetailActionSuccess) return s.driver;
    if (s is DriverDetailActionError) return s.driver;
    return null;
  }
}
