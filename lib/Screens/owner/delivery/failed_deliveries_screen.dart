import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';
import '../../../widgets/widgets.dart';
import 'report_issue_sheet.dart';

/// Missed / forfeited deliveries for the fleet owner. These are third-party jobs
/// the owner won (accepted quote) but did not complete within the delivery
/// window - the order was marked failed (owner at fault). Each row shows the
/// forfeited loss prominently and lets the owner dispute the job.
class FailedDeliveriesScreen extends StatefulWidget {
  const FailedDeliveriesScreen({super.key});

  @override
  State<FailedDeliveriesScreen> createState() => _FailedDeliveriesScreenState();
}

class _FailedDeliveriesScreenState extends State<FailedDeliveriesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiServiceUnified.instance.getFailedDeliveries();
    if (!mounted) return;
    if (res['status'] == 'success') {
      final data = (res['data'] as List?) ?? const [];
      setState(() {
        _items = data
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message'] as String? ?? 'Could not load failed deliveries.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SosAppBar(title: 'Missed Jobs'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 120.h),
          const EmptyState(
            icon: Icons.verified_rounded,
            title: 'No missed jobs',
            subtitle:
                'Deliveries you did not complete within the window would show here, with the amount you forfeited.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.r),
      itemCount: _items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, i) => _FailedJobCard(
        job: _items[i],
        onDispute: () => _dispute(_items[i]),
      ),
    );
  }

  void _dispute(Map<String, dynamic> job) {
    final requestId = (job['request_id'] as num?)?.toInt() ?? 0;
    if (requestId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job cannot be disputed.')),
      );
      return;
    }
    ReportIssueSheet.show(
      context,
      (t, d) => ApiServiceUnified.instance.reportDeliveryIssue(
        requestId: requestId,
        issueType: t,
        description: d,
      ),
    );
  }
}

class _FailedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onDispute;
  const _FailedJobCard({required this.job, required this.onDispute});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = scheme.error;

    final orderRef = (job['order_ref'] ?? '').toString();
    final reason = (job['failure_reason'] ?? 'Delivery not completed within the window.').toString();
    final pickup = (job['pickup_address'] ?? '').toString();
    final drop = (job['drop_address'] ?? '').toString();
    final when = (job['failed_at_display'] ?? '').toString();
    final loss = (job['loss_amount'] as num?)?.toDouble() ?? 0.0;
    final fee = (job['forfeited_fee'] as num?)?.toDouble() ?? 0.0;
    final deposit = (job['forfeited_deposit'] as num?)?.toDouble() ?? 0.0;

    return SosCard(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_rounded, color: errorColor, size: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Order #$orderRef',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
              ),
              if (when.isNotEmpty)
                Text(when,
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondary(context))),
            ],
          ),
          SizedBox(height: 10.h),
          // Forfeited loss - the headline number.
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: errorColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Forfeited: Rs ${loss.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: errorColor)),
                SizedBox(height: 2.h),
                Text(
                  deposit > 0
                      ? 'Delivery fee Rs ${fee.toStringAsFixed(2)} + deposit Rs ${deposit.toStringAsFixed(2)}'
                      : 'Delivery fee Rs ${fee.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          _line(context, Icons.info_outline_rounded, reason),
          if (pickup.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _line(context, Icons.my_location_rounded, 'Pickup: $pickup'),
          ],
          if (drop.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _line(context, Icons.location_on_rounded, 'Drop: $drop'),
          ],
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDispute,
              icon: Icon(Icons.report_gmailerrorred_outlined, size: 18.r),
              label: const Text('Dispute this job'),
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: BorderSide(color: errorColor.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.r, color: AppTheme.textSecondary(context)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: scheme.onSurface.withValues(alpha: 0.8))),
        ),
      ],
    );
  }
}
