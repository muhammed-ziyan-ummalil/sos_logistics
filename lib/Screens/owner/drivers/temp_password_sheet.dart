import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/app_theme.dart';

class TempPasswordSheet extends StatefulWidget {
  final String tempPassword;
  final VoidCallback onDismissed;

  const TempPasswordSheet({
    required this.tempPassword,
    required this.onDismissed,
    super.key,
  });

  @override
  State<TempPasswordSheet> createState() => _TempPasswordSheetState();
}

class _TempPasswordSheetState extends State<TempPasswordSheet> {
  bool _copied = false;

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: widget.tempPassword));
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent swipe-to-dismiss until confirmed
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Success icon
            Container(
              width: 56.r, height: 56.r,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28.r),
            ),
            SizedBox(height: 16.h),

            Text(
              'Driver Created Successfully',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16.h),

            // Warning banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Copy this password now. It will NOT be shown again.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Password display
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.divider),
              ),
              child: SelectableText(
                widget.tempPassword,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Copy button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyPassword,
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18.r),
                label: Text(_copied ? 'Copied!' : 'Copy Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _copied ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Dismiss button — only enabled after copy
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _copied ? widget.onDismissed : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _copied ? AppColors.textSecondary : AppColors.divider,
                  ),
                  foregroundColor: _copied ? AppColors.textSecondary : AppColors.divider,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: const Text('I have saved the password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
