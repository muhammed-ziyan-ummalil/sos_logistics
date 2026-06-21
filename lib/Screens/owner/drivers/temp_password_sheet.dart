import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // prevent swipe-to-dismiss until confirmed
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.divider(context),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Success icon
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: AppDesignTokens.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: AppDesignTokens.success, size: 28.r),
            ),
            SizedBox(height: 16.h),

            Text(
              'Driver Created Successfully',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16.h),

            // Warning banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppDesignTokens.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: AppDesignTokens.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppDesignTokens.warning, size: 18.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Copy this password now. It will NOT be shown again.',
                      style: TextStyle(
                        color: AppDesignTokens.warning,
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
            SosCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: SelectableText(
                widget.tempPassword,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.accent(context),
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Copy button — bg turns success when copied
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyPassword,
                icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18.r),
                label: Text(_copied ? 'Copied!' : 'Copy Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _copied
                      ? AppDesignTokens.success
                      : colorScheme.primary,
                  foregroundColor: _copied
                      ? Colors.white
                      : colorScheme.onPrimary,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Dismiss button — only enabled after copy
            SosButton(
              label: 'I have saved the password',
              variant: SosButtonVariant.outline,
              onPressed: _copied ? widget.onDismissed : null,
            ),
          ],
        ),
      ),
    );
  }
}
