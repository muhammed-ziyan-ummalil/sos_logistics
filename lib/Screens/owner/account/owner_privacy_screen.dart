import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_theme.dart';

class OwnerPrivacyScreen extends StatelessWidget {
  const OwnerPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppLightColors.background;
    final surfaceColor = isDark ? AppColors.surface : AppLightColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: BackButton(
            color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
        title: Text('Privacy Policy',
            style: TextStyle(color: textPrimary, fontSize: 17.sp)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: 'Privacy Policy',
              subtitle: 'Last updated: January 1, 2025',
              isDark: isDark,
            ),
            SizedBox(height: 20.h),
            _Section(
              title: '1. Information We Collect',
              isDark: isDark,
              content:
                  'When you use the SOSSSS Logistics platform as a vehicle owner, we collect the following types of information:\n\n'
                  '• Account Information: Your name, phone number, and email address provided during registration.\n\n'
                  '• Vehicle Information: Registration numbers, vehicle types, capacity, and insurance documents for vehicles added to your fleet.\n\n'
                  '• Driver Data: Names, phone numbers, KYC documents, and performance records of drivers registered under your account.\n\n'
                  '• Financial Information: Bank account details for withdrawal payouts, transaction history, and wallet balances.\n\n'
                  '• Location Data: General operational area and delivery route data associated with active deliveries.\n\n'
                  '• Usage Data: App interactions, session logs, and feature usage patterns to improve our services.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '2. How We Use Your Information',
              isDark: isDark,
              content:
                  '• To operate and maintain the SOSSSS Logistics platform and facilitate delivery operations.\n\n'
                  '• To process payments, manage wallet transactions, and execute withdrawal requests to your registered bank account.\n\n'
                  '• To verify driver identities through our KYC process and maintain fleet safety standards.\n\n'
                  '• To provide operational insights, analytics, and performance reporting for your fleet.\n\n'
                  '• To send important notifications about deliveries, driver activity, and account security.\n\n'
                  '• To comply with applicable laws, resolve disputes, and enforce our Terms of Service.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '3. Data Sharing',
              isDark: isDark,
              content:
                  'We do not sell your personal data to third parties. We may share information in the following limited circumstances:\n\n'
                  '• Service Providers: Trusted third-party partners who assist in operating the platform (payment processors, cloud infrastructure, KYC verification services) under strict confidentiality agreements.\n\n'
                  '• Buyers and Sellers: Relevant delivery information (driver name, vehicle number, estimated arrival) is shared with marketplace participants for active deliveries associated with your fleet.\n\n'
                  '• Legal Requirements: When required by law, court order, or government regulation, we may disclose necessary information to authorities.\n\n'
                  '• Business Transfers: In the event of a merger or acquisition, your data may be transferred to the successor entity with the same privacy protections.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '4. Data Retention',
              isDark: isDark,
              content:
                  'We retain your account data for as long as your account is active or as needed to provide services. Financial transaction records are retained for a minimum of 7 years to comply with financial regulations. KYC documents are retained for the duration required by applicable law. You may request deletion of non-mandatory data by contacting our support team.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '5. Security',
              isDark: isDark,
              content:
                  'We implement industry-standard security measures including:\n\n'
                  '• Encrypted data transmission using TLS/HTTPS protocols.\n\n'
                  '• Secure token-based authentication with automatic session expiry.\n\n'
                  '• Access controls limiting employee access to personal data on a need-to-know basis.\n\n'
                  '• Regular security audits and vulnerability assessments.\n\n'
                  'However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security and encourage you to use strong passwords and keep your credentials confidential.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '6. Your Rights',
              isDark: isDark,
              content:
                  'You have the following rights regarding your personal data:\n\n'
                  '• Access: Request a copy of the personal data we hold about you.\n\n'
                  '• Correction: Update or correct inaccurate information through your account settings or by contacting support.\n\n'
                  '• Deletion: Request deletion of your account and associated data, subject to legal retention requirements.\n\n'
                  '• Portability: Request your data in a machine-readable format.\n\n'
                  'To exercise these rights, contact us at privacy@sossss.net.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '7. Cookies and Tracking',
              isDark: isDark,
              content:
                  'Our mobile application uses device identifiers and local storage to maintain your session and preferences. We do not use advertising cookies or cross-app tracking. Analytics tools are used solely to improve app performance and user experience.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '8. Changes to This Policy',
              isDark: isDark,
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of significant changes via in-app notification or email. Your continued use of the platform after changes take effect constitutes your acceptance of the revised policy.',
            ),
            SizedBox(height: 16.h),
            _Section(
              title: '9. Contact Us',
              isDark: isDark,
              content:
                  'For privacy-related inquiries or to exercise your data rights, contact:\n\n'
                  'Email: privacy@sossss.net\n'
                  'Address: SOSSSS Technologies, Nigeria\n'
                  'Support Hours: Monday – Friday, 9:00 AM – 6:00 PM WAT',
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  const _Header(
      {required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final primary = isDark ? AppColors.primaryLight : AppLightColors.primary;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.privacy_tip_rounded, color: primary, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                Text(subtitle,
                    style: TextStyle(fontSize: 11.sp, color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final bool isDark;
  const _Section(
      {required this.title, required this.content, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final dividerColor = isDark ? AppColors.divider : AppLightColors.divider;
    final accentColor = isDark ? AppColors.accent : AppLightColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.only(left: 13.w),
          child: Text(content,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: textSecondary,
                  height: 1.6)),
        ),
        SizedBox(height: 8.h),
        Divider(color: dividerColor),
      ],
    );
  }
}
