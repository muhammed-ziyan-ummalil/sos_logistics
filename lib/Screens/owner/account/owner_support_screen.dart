import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

class OwnerSupportScreen extends StatefulWidget {
  const OwnerSupportScreen({super.key});

  @override
  State<OwnerSupportScreen> createState() => _OwnerSupportScreenState();
}

class _OwnerSupportScreenState extends State<OwnerSupportScreen> {
  int? _expandedFaq;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: const SosAppBar(title: 'Support'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupportHeader(),
            SizedBox(height: 24.h),
            _ContactSection(),
            SizedBox(height: 24.h),
            _FaqSection(
                expandedIndex: _expandedFaq,
                onToggle: (i) =>
                    setState(() => _expandedFaq = _expandedFaq == i ? null : i)),
          ],
        ),
      ),
    );
  }
}

// ─── Support header ───────────────────────────────────────────────────────────

class _SupportHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SosCard(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.support_agent_rounded, color: primary, size: 24.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('We\'re here to help',
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context))),
                SizedBox(height: 3.h),
                Text(
                    'Reach out for account help, delivery issues, or payment queries.',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary(context),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact section ──────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone_rounded, color: accentColor, size: 16.r),
            SizedBox(width: 6.w),
            Text('CONTACT US',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8)),
          ],
        ),
        SizedBox(height: 14.h),
        _ContactTile(
          icon: Icons.email_outlined,
          label: 'Email Support',
          value: 'support@sossss.net',
          subtitle: 'Response within 24 hours',
          onTap: () => _copyToClipboard(context, 'support@sossss.net'),
        ),
        SizedBox(height: 10.h),
        _ContactTile(
          icon: Icons.phone_outlined,
          label: 'Phone / WhatsApp',
          value: '+234 800 767 7777',
          subtitle: 'Mon-Fri, 9:00 AM - 6:00 PM WAT',
          onTap: () => _copyToClipboard(context, '+2348007677777'),
        ),
        SizedBox(height: 10.h),
        _ContactTile(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Live Chat',
          value: 'Available in app',
          subtitle: 'Fastest response during business hours',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live chat coming soon!')),
            );
          },
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $value'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SosCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: primary, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 2.h),
                Text(value,
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context))),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Icon(Icons.copy_rounded,
              size: 16.r, color: AppTheme.divider(context)),
        ],
      ),
    );
  }
}

// ─── FAQ section ──────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  const _FaqSection({
    required this.expandedIndex,
    required this.onToggle,
  });

  static const _faqs = [
    (
      'How do I add a driver to my fleet?',
      'Go to the Manage tab and tap "Add Driver". You\'ll enter the driver\'s name and phone number. The driver will receive temporary login credentials via SMS. Their account requires KYC approval before they can go online.'
    ),
    (
      'Why can\'t my driver go online?',
      'Drivers must be in "Active" status and have a vehicle assigned before they can go online. If their status shows "CREATED", they are awaiting admin activation. Ensure they have completed KYC verification and have been activated.'
    ),
    (
      'How do I withdraw my earnings?',
      'Go to Account -> My Wallet -> Withdraw. Enter the amount and submit. The funds will be transferred to your registered bank account within 1-3 business days. Ensure your Bank Details are up to date under Account settings.'
    ),
    (
      'What vehicle types are supported?',
      'SOSSSS Logistics supports trucks, vans, pickup trucks, and motorbikes. When adding a vehicle, select the appropriate type to ensure correct delivery order matching.'
    ),
    (
      'How is my fleet\'s performance calculated?',
      'Performance metrics are derived from delivery completion records. Acceptance rate = (completed deliveries / total assigned deliveries) x 100. Missed jobs are counted when a driver fails to complete an accepted delivery.'
    ),
    (
      'Can I temporarily deactivate a driver?',
      'Yes. Open the driver\'s detail page from the Drivers list and change their status to "Suspend". This prevents them from going online and accepting new deliveries without removing them from your fleet.'
    ),
    (
      'What happens to my wallet when a delivery is completed?',
      'When a delivery is successfully completed, the payment is released from escrow and credited to your wallet as "Escrow Release". You can then request a withdrawal at any time.'
    ),
    (
      'How do I update my bank details?',
      'Go to Account -> Bank Details. Enter your bank name, account number, account holder name, and IFSC/sort code. Withdrawals are always made to the most recently saved bank details.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline_rounded, color: accentColor, size: 16.r),
            SizedBox(width: 6.w),
            Text('FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8)),
          ],
        ),
        SizedBox(height: 14.h),
        ..._faqs.asMap().entries.map((entry) {
          final i = entry.key;
          final faq = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _FaqItem(
              question: faq.$1,
              answer: faq.$2,
              isExpanded: expandedIndex == i,
              onTap: () => onToggle(i),
            ),
          );
        }),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accent(context);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isExpanded
              ? accentColor.withValues(alpha: 0.04)
              : scheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: isExpanded
                  ? accentColor.withValues(alpha: 0.3)
                  : scheme.outline,
              width: isExpanded ? 1.2 : 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(question,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context))),
                ),
                SizedBox(width: 8.w),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20.r,
                      color: isExpanded
                          ? accentColor
                          : AppTheme.textSecondary(context)),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 10.h),
              Text(answer,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary(context),
                      height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
