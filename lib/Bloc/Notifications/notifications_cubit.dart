import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utility/api_service.dart';
import 'notifications_state.dart';

/// Loads in-app notifications for the current role ('owner' | 'driver').
/// The list endpoint marks everything seen server-side, so the unread badge
/// clears once the screen is opened.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsInitial());

  final _api = ApiServiceUnified.instance;

  Future<void> fetch(String role) async {
    emit(NotificationsLoading());
    final res = await _api.getNotifications(role);
    if (res['status'] == 'valid') {
      final raw = (res['data']?['items'] as List?) ?? const [];
      final items = raw
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      emit(NotificationsLoaded(items));
    } else {
      emit(NotificationsError(
          (res['message'] ?? 'Failed to load notifications').toString()));
    }
  }

  /// Unread count for the bell badge. Returns 0 on any failure.
  Future<int> unreadCount(String role) async {
    final res = await _api.getNotificationSummary(role);
    if (res['status'] == 'valid') {
      final c = res['data']?['unread_count'];
      return (c is int) ? c : int.tryParse('$c') ?? 0;
    }
    return 0;
  }
}
