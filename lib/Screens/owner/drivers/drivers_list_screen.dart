import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  late TabController _tabCtrl;

  static const _tabs = ['All', 'Active', 'Pending', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiServiceV2.instance.get('owner/drivers');
    if (res['status'] == 'success') {
      final list = (res['data']?['drivers'] as List?) ?? [];
      setState(() {
        _drivers =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message'] as String? ?? 'Failed to load drivers.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _drivers;

    // Tab filter
    switch (_tabCtrl.index) {
      case 1: // Active
        list = list.where((d) => d['status'] == 'active').toList();
        break;
      case 2: // Pending / Created
        list = list
            .where((d) =>
                d['status'] == 'pending_admin' ||
                d['status'] == 'pending' ||
                d['status'] == 'created')
            .toList();
        break;
      case 3: // Suspended
        list = list
            .where((d) =>
                d['status'] == 'suspended' ||
                d['status'] == 'disabled' ||
                d['status'] == 'rejected')
            .toList();
        break;
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((d) =>
              (d['name'] as String? ?? '').toLowerCase().contains(q) ||
              (d['phone'] as String? ?? '').contains(q) ||
              (d['email'] as String? ?? '').toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  int _countForTab(int index) {
    return switch (index) {
      0 => _drivers.length,
      1 => _drivers.where((d) => d['status'] == 'active').length,
      2 => _drivers
          .where((d) =>
              d['status'] == 'pending_admin' ||
              d['status'] == 'pending' ||
              d['status'] == 'created')
          .length,
      3 => _drivers
          .where((d) =>
              d['status'] == 'suspended' ||
              d['status'] == 'disabled' ||
              d['status'] == 'rejected')
          .length,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;
    final primaryColor = isDark ? AppColors.primaryLight : AppLightColors.primary;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final added =
              await Navigator.pushNamed(context, AppRoutes.v2AddDriver);
          if (added == true && mounted) _load();
        },
        icon: Icon(Icons.person_add_rounded, size: 18.r),
        label: Text('Add Driver',
            style:
                TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── App Bar ───────────────────────────────────────────────────
          Container(
            color: surfaceColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 4.h, 8.w, 0),
                    child: Row(
                      children: [
                        BackButton(color: textSecondary),
                        Expanded(
                          child: Text('Drivers',
                              style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary)),
                        ),
                        // Stats pill
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text('${_drivers.length} total',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor)),
                        ),
                        SizedBox(width: 4.w),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded,
                              color: textSecondary, size: 20.r),
                          onPressed: _loading ? null : _load,
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                    child: Container(
                      height: 38.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.card
                            : AppLightColors.background,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: dividerColor),
                      ),
                      child: TextField(
                        style: TextStyle(
                            color: textPrimary, fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText: 'Search name, phone, email…',
                          hintStyle: TextStyle(
                              color: textSecondary, fontSize: 13.sp),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: textSecondary, size: 18.r),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8.h),
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                      ),
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: accentColor,
                    unselectedLabelColor: textSecondary,
                    indicatorColor: accentColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w600),
                    unselectedLabelStyle:
                        TextStyle(fontSize: 12.sp),
                    tabs: _tabs.asMap().entries.map((e) {
                      final count = _countForTab(e.key);
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.value),
                            if (count > 0 && e.key > 0) ...[
                              SizedBox(width: 4.w),
                              Container(
                                width: 16.r,
                                height: 16.r,
                                decoration: BoxDecoration(
                                  color: e.key == 2
                                      ? (isDark
                                          ? AppColors.warning
                                          : AppLightColors.warning)
                                      : e.key == 3
                                          ? (isDark
                                              ? AppColors.error
                                              : AppLightColors.error)
                                          : accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : count.toString(),
                                    style: TextStyle(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Divider(color: dividerColor, height: 1),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2.5))
                : _error != null
                    ? _ErrorState(
                        error: _error!,
                        isDark: isDark,
                        onRetry: _load)
                    : _filtered.isEmpty
                        ? _EmptyState(
                            tabIndex: _tabCtrl.index,
                            hasSearch: _searchQuery.isNotEmpty,
                            isDark: isDark,
                            onAdd: () async {
                              final added = await Navigator.pushNamed(
                                  context, AppRoutes.v2AddDriver);
                              if (added == true && mounted) _load();
                            })
                        : RefreshIndicator(
                            color: accentColor,
                            backgroundColor: isDark
                                ? AppColors.card
                                : AppLightColors.card,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                  16.w, 12.h, 16.w, 100.h),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: _DriverCard(
                                  driver: _filtered[i],
                                  isDark: isDark,
                                  onTap: () async {
                                    final d = _filtered[i];
                                    final id = d['id']?.toString() ??
                                        d['driver_id']?.toString() ??
                                        '';
                                    if (id.isEmpty) return;
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.v2DriverDetail,
                                      arguments: {
                                        'driver_id': id,
                                        'driver': d,
                                      },
                                    );
                                    _load(); // Refresh after returning
                                  },
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Driver card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool isDark;
  final VoidCallback onTap;

  const _DriverCard({
    required this.driver,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primaryColor = isDark ? AppColors.primaryLight : AppLightColors.primary;

    final name = driver['name'] as String? ?? '—';
    final email = driver['email'] as String? ?? '';
    final phone = driver['phone'] as String? ?? '—';
    final status = driver['status'] as String? ?? '';
    final isOnline = driver['is_online'] == true ||
        driver['is_online'] == 1 ||
        driver['is_online'] == '1';
    final vehicle = driver['vehicle'] as Map<String, dynamic>?;
    final vehiclePlate = vehicle?['reg_number'] as String?;
    final vehicleType = vehicle?['type'] as String?;

    final statusColor = _statusColor(status, isDark);
    final statusLabel = _statusLabel(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: dividerColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Avatar + online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: primaryColor.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10.r,
                    height: 10.r,
                    decoration: BoxDecoration(
                      color:
                          isOnline ? AppColors.success : dividerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),

            // Name + email + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  SizedBox(height: 2.h),
                  if (email.isNotEmpty)
                    Text(email,
                        style: TextStyle(
                            fontSize: 11.sp, color: textSecondary)),
                  Text(phone,
                      style: TextStyle(
                          fontSize: 11.sp, color: textSecondary)),
                  SizedBox(height: 5.h),
                  // Vehicle tag
                  Row(
                    children: [
                      Icon(Icons.directions_car_rounded,
                          size: 10.r,
                          color: vehiclePlate != null
                              ? textSecondary
                              : dividerColor),
                      SizedBox(width: 3.w),
                      Text(
                        vehiclePlate != null
                            ? '$vehiclePlate${vehicleType != null ? ' · ${vehicleType.toUpperCase()}' : ''}'
                            : 'No vehicle assigned',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: vehiclePlate != null
                              ? textSecondary
                              : (isDark
                                  ? AppColors.error
                                  : AppLightColors.error)
                                  .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
                SizedBox(height: 6.h),
                Icon(Icons.chevron_right_rounded,
                    size: 18.r, color: dividerColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s, bool isDark) => switch (s) {
        'active' => AppColors.success,
        'suspended' || 'disabled' || 'rejected' =>
          isDark ? AppColors.error : AppLightColors.error,
        'pending_admin' || 'pending' || 'created' =>
          isDark ? AppColors.warning : AppLightColors.warning,
        _ => isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
      };

  String _statusLabel(String s) => switch (s) {
        'active' => 'ACTIVE',
        'pending_admin' || 'created' => 'PENDING',
        'suspended' => 'SUSPENDED',
        'disabled' => 'DISABLED',
        'rejected' => 'REJECTED',
        _ => s.toUpperCase().replaceAll('_', ' '),
      };
}

// ─── Empty + Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final bool hasSearch;
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.tabIndex,
    required this.hasSearch,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;

    String message;
    IconData icon;
    if (hasSearch) {
      message = 'No drivers match your search.';
      icon = Icons.search_off_rounded;
    } else {
      switch (tabIndex) {
        case 1:
          message = 'No active drivers.';
          icon = Icons.check_circle_outline;
          break;
        case 2:
          message = 'No pending drivers.';
          icon = Icons.hourglass_empty_rounded;
          break;
        case 3:
          message = 'No suspended drivers.';
          icon = Icons.block_rounded;
          break;
        default:
          message = 'No drivers yet.\nAdd your first driver to get started.';
          icon = Icons.people_outline;
      }
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.r, color: dividerColor),
            SizedBox(height: 16.h),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: textSecondary)),
            if (!hasSearch && tabIndex == 0) ...[
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.person_add_rounded, size: 16.r),
                label: const Text('Add Driver'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.error, required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: isDark ? AppColors.error : AppLightColors.error,
                size: 40.r),
            SizedBox(height: 12.h),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                    fontSize: 13.sp)),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
