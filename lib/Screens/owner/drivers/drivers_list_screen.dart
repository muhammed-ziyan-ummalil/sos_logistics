import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';
import '../../../widgets/widgets.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () async {
          final added =
              await Navigator.pushNamed(context, AppRoutes.v2AddDriver);
          if (added == true && mounted) _load();
        },
        icon: Icon(Icons.person_add_rounded, size: 18.r),
        label: Text('Add Driver',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── App Bar ───────────────────────────────────────────────────
          Container(
            color: colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 4.h, 8.w, 0),
                    child: Row(
                      children: [
                        BackButton(color: AppTheme.textSecondary(context)),
                        Expanded(
                          child: Text(
                            'Drivers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        // Stats pill
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '${_drivers.length} total',
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded,
                              color: AppTheme.textSecondary(context),
                              size: 20.r),
                          onPressed: _loading ? null : _load,
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                    child: TextField(
                      style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 13.sp),
                      decoration: InputDecoration(
                        hintText: 'Search name, phone, email…',
                        hintStyle: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 13.sp),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppTheme.textSecondary(context),
                            size: 18.r),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: AppTheme.accent(context),
                    unselectedLabelColor: AppTheme.textSecondary(context),
                    indicatorColor: AppTheme.accent(context),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                    tabs: _tabs.asMap().entries.map((e) {
                      final count = _countForTab(e.key);
                      final badgeTone = e.key == 2
                          ? SosTone.warning
                          : e.key == 3
                              ? SosTone.error
                              : SosTone.success;
                      return Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                e.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (count > 0 && e.key > 0) ...[
                              SizedBox(width: 4.w),
                              SosChip(
                                label: count > 9 ? '9+' : count.toString(),
                                tone: badgeTone,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Divider(color: AppTheme.divider(context), height: 1),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? _SkeletonList()
                : _error != null
                    ? ErrorState(
                        message: _error!,
                        onRetry: _load,
                      )
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppTheme.accent(context),
                            backgroundColor: AppTheme.card(context),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                  16.w, 12.h, 16.w, 100.h),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: _DriverCard(
                                  driver: _filtered[i],
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

  Widget _buildEmpty() {
    String title;
    String? subtitle;
    IconData icon;
    if (_searchQuery.isNotEmpty) {
      title = 'No results';
      subtitle = 'No drivers match your search.';
      icon = Icons.search_off_rounded;
    } else {
      switch (_tabCtrl.index) {
        case 1:
          title = 'No active drivers';
          icon = Icons.check_circle_outline;
          break;
        case 2:
          title = 'No pending drivers';
          icon = Icons.hourglass_empty_rounded;
          break;
        case 3:
          title = 'No suspended drivers';
          icon = Icons.block_rounded;
          break;
        default:
          title = 'No drivers yet';
          subtitle = 'Add your first driver to get started.';
          icon = Icons.people_outline;
      }
    }
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: (!_searchQuery.isNotEmpty && _tabCtrl.index == 0)
          ? 'Add Driver'
          : null,
      onAction: (!_searchQuery.isNotEmpty && _tabCtrl.index == 0)
          ? () async {
              final added = await Navigator.pushNamed(
                  context, AppRoutes.v2AddDriver);
              if (added == true && mounted) _load();
            }
          : null,
    );
  }
}

// ─── Skeleton list ────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SosCard(
          child: Row(
            children: [
              SkeletonBox(
                  width: 44,
                  height: 44,
                  radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 13),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 11),
                    const SizedBox(height: 5),
                    SkeletonBox(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Driver card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onTap;

  const _DriverCard({
    required this.driver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

    final statusTone = _statusTone(status);
    final statusLabel = _statusLabel(status);

    return SosCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          // Avatar + online dot
          Stack(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
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
                    color: isOnline
                        ? AppDesignTokens.success
                        : AppTheme.divider(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.card(context), width: 1.5),
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
                        color: AppTheme.textPrimary(context))),
                SizedBox(height: 2.h),
                if (email.isNotEmpty)
                  Text(email,
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondary(context))),
                Text(phone,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondary(context))),
                SizedBox(height: 5.h),
                // Vehicle tag
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded,
                        size: 10.r,
                        color: vehiclePlate != null
                            ? AppTheme.textSecondary(context)
                            : AppTheme.divider(context)),
                    SizedBox(width: 3.w),
                    Text(
                      vehiclePlate != null
                          ? '$vehiclePlate${vehicleType != null ? ' · ${vehicleType.toUpperCase()}' : ''}'
                          : 'No vehicle assigned',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: vehiclePlate != null
                            ? AppTheme.textSecondary(context)
                            : colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status + chevron
          Flexible(
            flex: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SosChip(label: statusLabel, tone: statusTone),
                SizedBox(height: 6.h),
                Icon(Icons.chevron_right_rounded,
                    size: 18.r, color: AppTheme.divider(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SosTone _statusTone(String s) => switch (s) {
        'active' => SosTone.success,
        'suspended' || 'disabled' || 'rejected' => SosTone.error,
        'pending_admin' || 'pending' || 'created' => SosTone.warning,
        _ => SosTone.neutral,
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
