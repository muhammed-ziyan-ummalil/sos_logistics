import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Bloc/Notifications/notifications_cubit.dart';
import '../../Bloc/Notifications/notifications_state.dart';
import '../../core/app_theme.dart';
import '../../widgets/widgets.dart';

class NotificationsScreen extends StatelessWidget {
  /// 'owner' or 'driver'.
  final String role;
  const NotificationsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit()..fetch(role),
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        appBar: const SosAppBar(title: 'Notifications'),
        body: Builder(
          builder: (ctx) => BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (_, state) {
              if (state is NotificationsLoading || state is NotificationsInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is NotificationsError) {
                return ErrorState(
                  message: state.message,
                  onRetry: () => ctx.read<NotificationsCubit>().fetch(role),
                );
              }
              final items = (state as NotificationsLoaded).items;
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'No notifications',
                  subtitle: 'Delivery and approval updates will show up here.',
                );
              }
              return RefreshIndicator(
                onRefresh: () => ctx.read<NotificationsCubit>().fetch(role),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, i) => _NotificationTile(item: items[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SosCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.notifications_rounded, color: primary, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    if (item.isUnread)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        margin: EdgeInsets.only(left: 6.w, top: 4.h),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(item.message, style: Theme.of(context).textTheme.bodyMedium),
                if (item.dateTime.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(item.dateTime,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
