import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'availability_state.dart';

class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit() : super(AvailabilityInitial());

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Future<void> toggle({double? lat, double? lng}) async {
    final target = _isOnline ? 'offline' : 'online';
    emit(AvailabilityLoading());
    final data = <String, dynamic>{'status': target};
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;

    final res = await ApiService.instance.post('driver/availability', data: data);
    if (res['status'] == 'success') {
      _isOnline = target == 'online';
      emit(AvailabilityUpdated(_isOnline));
    } else {
      emit(AvailabilityError(res['message'] ?? 'Failed to update status.'));
    }
  }

  void setOnlineState(bool value) {
    _isOnline = value;
    emit(AvailabilityUpdated(_isOnline));
  }
}
