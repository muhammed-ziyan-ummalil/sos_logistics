import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_theme.dart';
import '../../../utility/api_service.dart';
import '../../../widgets/widgets.dart';

/// Bottom sheet letting a logistics owner raise an issue on a delivery they are
/// running. POSTs to owner/delivery-issue (backend verifies ownership).
class ReportIssueSheet extends StatefulWidget {
  final int requestId;

  const ReportIssueSheet({super.key, required this.requestId});

  static Future<void> show(BuildContext context, int requestId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ReportIssueSheet(requestId: requestId),
      ),
    );
  }

  @override
  State<ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<ReportIssueSheet> {
  // Keys MUST match DeliveryIssueReportModel::ISSUE_TYPES on the backend.
  static const Map<String, String> _types = {
    'vehicle_breakdown': 'Vehicle breakdown',
    'accident': 'Accident',
    'buyer_unreachable': 'Buyer unreachable',
    'seller_unreachable': 'Seller unreachable',
    'wrong_address': 'Wrong / unclear address',
    'goods_damaged': 'Goods damaged',
    'goods_missing': 'Goods missing',
    'payment_dispute': 'Payment dispute',
    'other': 'Other',
  };

  String? _type;
  final TextEditingController _descCtr = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an issue type.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final res = await ApiServiceUnified.instance.reportDeliveryIssue(
      requestId: widget.requestId,
      issueType: _type!,
      description: _descCtr.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final ok = res['status'] == 'success';
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (res['message'] as String? ?? 'Issue reported.')
            : (res['message'] as String? ?? 'Could not report the issue.')),
        backgroundColor:
            ok ? AppDesignTokens.success : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Report an issue',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface)),
          SizedBox(height: 4.h),
          Text(
            'Tell us what went wrong with this delivery. Our team will review it.',
            style: TextStyle(
                fontSize: 12.sp, color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: scheme.outline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _type,
                hint: const Text('Select issue type'),
                items: _types.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _descCtr,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the issue (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SosButton(
            label: _submitting ? 'Submitting…' : 'Submit report',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
