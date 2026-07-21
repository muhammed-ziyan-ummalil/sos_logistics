import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerKyc/owner_kyc_cubit.dart';
import '../../../Bloc/OwnerKyc/owner_kyc_state.dart';
import '../../../utility/shared_preference.dart';
import '../../../widgets/widgets.dart';
import 'owner_kyc_screen.dart';

/// Owner KYC details — Overview / Details / Documents tabs.
/// Mirrors the agent app's KYC Details screen. KYC gates wallet
/// withdrawals only; owner features unlock on account approval.
class OwnerKycDetailsScreen extends StatefulWidget {
  const OwnerKycDetailsScreen({super.key});

  @override
  State<OwnerKycDetailsScreen> createState() => _OwnerKycDetailsScreenState();
}

class _OwnerKycDetailsScreenState extends State<OwnerKycDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _name = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<OwnerKycCubit>().fetchDetails();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    final info = await AppPrefs.getV2Session();
    if (mounted) {
      setState(() {
        _name = info['name'] ?? '';
        _phone = info['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OwnerKycCubit(),
          child: const OwnerKycScreen(),
        ),
      ),
    );
    if (mounted) context.read<OwnerKycCubit>().fetchDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Details'),
            Tab(text: 'Documents'),
          ],
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: BlocBuilder<OwnerKycCubit, OwnerKycState>(
        builder: (context, state) {
          if (state is OwnerKycLoading ||
              state is OwnerKycInitial ||
              state is OwnerKycSubmitting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OwnerKycError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<OwnerKycCubit>().fetchDetails(),
            );
          }

          final loaded = state is OwnerKycLoaded ? state : null;
          final document = loaded?.document;
          final kycStatus = _resolveStatus(loaded);

          return Column(
            children: [
              _ProfileHeader(name: _name, kycStatus: kycStatus),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(
                      kycStatus: kycStatus,
                      kycMessage: loaded?.kycMessage,
                      rejectionReason:
                          (document?['rejection_reason'] as String?)?.trim(),
                      verifiedViaOtherRole:
                          kycStatus == 'approved' && document == null,
                      onSubmit: _openForm,
                    ),
                    _DetailsTab(name: _name, phone: _phone),
                    _DocumentsTab(document: document),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _resolveStatus(OwnerKycLoaded? state) {
    final s = (state?.status ?? 'none').toLowerCase();
    if (s == 'none' || s.isEmpty) return 'not_submitted';
    return s;
  }
}

// ─────────────────────────────────────────────────────────────
// Profile header — name + status badge
// ─────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String kycStatus;

  const _ProfileHeader({required this.name, required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.person, size: 28.sp, color: Colors.grey),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 5.h),
                _KycStatusBadge(kycStatus: kycStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — Overview: status + guidance + CTA
// ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final String kycStatus;
  final String? kycMessage;
  final String? rejectionReason;
  final bool verifiedViaOtherRole;
  final VoidCallback onSubmit;

  const _OverviewTab({
    required this.kycStatus,
    required this.kycMessage,
    required this.rejectionReason,
    required this.verifiedViaOtherRole,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isNotSubmitted = kycStatus == 'not_submitted';
    final isRejected = kycStatus == 'rejected';
    final isVerified = kycStatus == 'approved' || kycStatus == 'verified';
    final isPending = kycStatus == 'pending' || kycStatus == 'under_review';

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusSummaryCard(kycStatus: kycStatus),
          SizedBox(height: 16.h),
          if (isNotSubmitted)
            _GuidanceBanner(
              icon: Icons.info_outline_rounded,
              color: Colors.blue,
              message:
                  'KYC verification is not completed. Submit your documents to enable wallet withdrawals.',
            )
          else if (isRejected)
            _GuidanceBanner(
              icon: Icons.cancel_outlined,
              color: Theme.of(context).colorScheme.error,
              message: (rejectionReason?.isNotEmpty ?? false)
                  ? 'Your KYC was rejected: $rejectionReason'
                  : ((kycMessage?.trim().isNotEmpty ?? false)
                      ? 'Your KYC was rejected: ${kycMessage!.trim()}'
                      : 'Your KYC was rejected. Please re-submit with correct documents.'),
            )
          else if (isPending)
            _GuidanceBanner(
              icon: Icons.hourglass_top_rounded,
              color: Colors.orange,
              message:
                  'Your KYC documents are under review. You will be notified once verification is complete.',
            )
          else if (isVerified)
            _GuidanceBanner(
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green,
              message: verifiedViaOtherRole
                  ? 'KYC verified via your other SOS account role. Wallet withdrawals are enabled.'
                  : 'KYC verification is complete. Wallet withdrawals are enabled.',
            ),
          SizedBox(height: 20.h),
          if (isNotSubmitted || isRejected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: Icon(
                  isRejected
                      ? Icons.refresh_rounded
                      : Icons.upload_file_rounded,
                  size: 18,
                ),
                label: Text(
                  isRejected ? 'Re-submit Documents' : 'Submit KYC Documents',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRejected ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          if (isVerified && !verifiedViaOtherRole)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Update KYC Details'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          SizedBox(height: 12.h),
          _QuickGuide(isVerified: isVerified),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — Details: personal info
// ─────────────────────────────────────────────────────────────
class _DetailsTab extends StatelessWidget {
  final String name;
  final String phone;

  const _DetailsTab({required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Details',
                ),
                SizedBox(height: 14.h),
                _InfoRow(label: 'Name', value: name.isNotEmpty ? name : '-'),
                _divider(context),
                _InfoRow(
                    label: 'Mobile', value: phone.isNotEmpty ? phone : '-'),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 22.h,
        thickness: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      );
}

// ─────────────────────────────────────────────────────────────
// Tab 3 — Documents: KYC numbers + uploaded files
// ─────────────────────────────────────────────────────────────
class _DocumentsTab extends StatelessWidget {
  final Map<String, dynamic>? document;

  const _DocumentsTab({required this.document});

  String _str(String key) => (document?[key] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return const _EmptyTabState(
        icon: Icons.description_outlined,
        message: 'No KYC documents submitted yet.',
      );
    }

    final panUrl = _str('pan_document');
    final aadharFrontUrl = _str('aadhar_front');
    final aadharBackUrl = _str('aadhar_back');
    final hasDocs = panUrl.isNotEmpty ||
        aadharFrontUrl.isNotEmpty ||
        aadharBackUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.badge_outlined,
                  title: 'KYC Information',
                ),
                SizedBox(height: 14.h),
                _InfoRow(
                    label: 'Full Name',
                    value:
                        _str('full_name').isNotEmpty ? _str('full_name') : '-'),
                _divider(context),
                _InfoRow(
                    label: 'Date of Birth',
                    value: _str('dob').isNotEmpty ? _str('dob') : '-'),
                _divider(context),
                _InfoRow(
                    label: 'PAN Number',
                    value: _str('pan_number').isNotEmpty
                        ? _str('pan_number')
                        : '-'),
                _divider(context),
                _InfoRow(
                    label: 'Aadhar Number',
                    value: _str('aadhar_number').isNotEmpty
                        ? _str('aadhar_number')
                        : '-'),
              ],
            ),
          ),
          if (hasDocs) ...[
            SizedBox(height: 14.h),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.folder_outlined,
                    title: 'Uploaded Documents',
                  ),
                  SizedBox(height: 14.h),
                  if (panUrl.isNotEmpty)
                    _DocumentTile(
                      title: 'PAN Document',
                      url: panUrl,
                      icon: Icons.credit_card,
                    ),
                  if (aadharFrontUrl.isNotEmpty) ...[
                    if (panUrl.isNotEmpty) _divider(context),
                    _DocumentTile(
                      title: 'Aadhar Front',
                      url: aadharFrontUrl,
                      icon: Icons.badge,
                    ),
                  ],
                  if (aadharBackUrl.isNotEmpty) ...[
                    _divider(context),
                    _DocumentTile(
                      title: 'Aadhar Back',
                      url: aadharBackUrl,
                      icon: Icons.badge,
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 22.h,
        thickness: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      );
}

// ─────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────

Widget _card(BuildContext context, {required Widget child}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
      ),
    ),
    child: child,
  );
}

class _KycStatusBadge extends StatelessWidget {
  final String kycStatus;
  const _KycStatusBadge({required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (kycStatus) {
      case 'verified':
      case 'approved':
        color = Colors.green;
        label = 'KYC Verified';
        icon = Icons.verified_rounded;
        break;
      case 'pending':
      case 'under_review':
        color = Colors.orange;
        label = 'Under Review';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'KYC Rejected';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.grey;
        label = 'Not Submitted';
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  final String kycStatus;
  const _StatusSummaryCard({required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    final isVerified = kycStatus == 'verified' || kycStatus == 'approved';
    final isPending = kycStatus == 'pending' || kycStatus == 'under_review';
    final isRejected = kycStatus == 'rejected';

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (isVerified) {
      color = Colors.green;
      icon = Icons.verified_rounded;
      title = 'KYC Verified';
      subtitle = 'Your identity has been successfully verified.';
    } else if (isPending) {
      color = Colors.orange;
      icon = Icons.hourglass_top_rounded;
      title = 'Under Review';
      subtitle = 'Documents are being reviewed by our team.';
    } else if (isRejected) {
      color = Colors.red;
      icon = Icons.cancel_rounded;
      title = 'KYC Rejected';
      subtitle = 'Your documents did not pass verification.';
    } else {
      color = Colors.grey;
      icon = Icons.info_outline_rounded;
      title = 'Not Submitted';
      subtitle = 'Complete KYC to enable wallet withdrawals.';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickGuide extends StatelessWidget {
  final bool isVerified;
  const _QuickGuide({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.person_outlined, 'Personal Info', 'Name and date of birth'),
      (Icons.badge_outlined, 'KYC Documents', 'PAN card, Aadhar card photos'),
      (
        Icons.check_circle_outline_rounded,
        'Verification',
        'Admin reviews and approves'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KYC Process',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 10.h),
        ...steps.asMap().entries.map((e) {
          final idx = e.key;
          final step = e.value;
          final isDone = isVerified && idx < 3;
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : step.$1,
                    size: 14.sp,
                    color: isDone
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$2,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      step.$3,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GuidanceBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _GuidanceBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 6.w),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final String url;
  final IconData icon;

  const _DocumentTile({
    required this.title,
    required this.url,
    required this.icon,
  });

  void _showImage(BuildContext ctx) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('No image available')));
      return;
    }
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(ctx).colorScheme.primary),
                  ),
                );
              },
              errorBuilder: (ctx, error, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Text('Failed to load image',
                      style:
                          TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return InkWell(
      onTap: () => _showImage(ctx),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon,
                color: Theme.of(ctx).colorScheme.primary, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Tap to view document',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.visibility_outlined,
              color: Theme.of(ctx).colorScheme.primary, size: 18.sp),
        ],
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyTabState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
