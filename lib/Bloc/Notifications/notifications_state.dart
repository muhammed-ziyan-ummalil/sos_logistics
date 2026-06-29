class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String dateTime;
  final bool isUnread;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    required this.isUnread,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: (j['id'] is int) ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
        title: (j['title'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        dateTime: (j['date_time'] ?? '').toString(),
        isUnread: j['is_unread'] == true,
      );
}

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationItem> items;
  NotificationsLoaded(this.items);
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
