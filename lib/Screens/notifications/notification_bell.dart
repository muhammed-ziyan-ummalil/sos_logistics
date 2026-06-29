import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Bloc/Notifications/notifications_cubit.dart';
import '../../core/app_theme.dart';
import 'notifications_screen.dart';

/// App-bar bell with an unread badge. [role] is 'owner' or 'driver'.
/// Tapping opens the notifications list (which marks everything seen), then
/// the badge refreshes on return.
class NotificationBell extends StatefulWidget {
  final String role;
  const NotificationBell({super.key, required this.role});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationsCubit _cubit = NotificationsCubit();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _load() async {
    final c = await _cubit.unreadCount(widget.role);
    if (mounted) setState(() => _unread = c);
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationsScreen(role: widget.role)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded,
              color: AppTheme.textSecondary(context), size: 22.r),
          tooltip: 'Notifications',
          onPressed: _open,
        ),
        if (_unread > 0)
          Positioned(
            top: 10.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
