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

class _DriversListScreenState extends State<DriversListScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiServiceV2.instance.get('owner/drivers');
    if (res['status'] == 'success') {
      final list = (res['data']?['drivers'] as List?) ?? [];
      setState(() {
        _drivers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error   = res['message'] as String? ?? 'Failed to load drivers.';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'active'        => AppColors.success,
      'pending_admin' => AppColors.warning,
      'disabled'      => AppColors.error,
      'rejected'      => AppColors.error,
      _               => AppColors.textSecondary,
    };
  }

  Color _kycColor(String status) {
    return switch (status) {
      'approved'  => AppColors.success,
      'submitted' => AppColors.warning,
      'rejected'  => AppColors.error,
      _           => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Drivers'),
        backgroundColor: AppColors.surface,
        leading: BackButton(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20.r),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final added = await Navigator.pushNamed(context, AppRoutes.v2AddDriver);
          if (added == true) _load();
        },
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 14.sp)),
                      SizedBox(height: 16.h),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _drivers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 200.h),
                            Center(
                              child: Text(
                                'No drivers yet. Tap + to add one.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.r),
                          itemCount: _drivers.length,
                          itemBuilder: (ctx, i) {
                            final d = _drivers[i];
                            final status    = d['status'] as String? ?? '';
                            final kycStatus = d['kyc_status'] as String? ?? '';
                            return Card(
                              margin: EdgeInsets.only(bottom: 10.h),
                              child: Padding(
                                padding: EdgeInsets.all(14.r),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.15),
                                      child: Text(
                                        (d['name'] as String? ?? '?')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['name'] as String? ?? '—',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            d['phone'] as String? ?? '—',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Text(
                                            status.toUpperCase().replaceAll('_', ' '),
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                          decoration: BoxDecoration(
                                            color: _kycColor(kycStatus).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Text(
                                            'KYC: ${kycStatus.toUpperCase()}',
                                            style: TextStyle(
                                              color: _kycColor(kycStatus),
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
