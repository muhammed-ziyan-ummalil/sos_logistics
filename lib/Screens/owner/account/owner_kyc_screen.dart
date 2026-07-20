import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../Bloc/OwnerKyc/owner_kyc_cubit.dart';
import '../../../Bloc/OwnerKyc/owner_kyc_state.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

class OwnerKycScreen extends StatefulWidget {
  const OwnerKycScreen({super.key});

  @override
  State<OwnerKycScreen> createState() => _OwnerKycScreenState();
}

class _OwnerKycScreenState extends State<OwnerKycScreen> {
  final _fullNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();

  File? _panFile;
  File? _aadharFrontFile;
  File? _aadharBackFile;

  String _panUrl = '';
  String _aadharFrontUrl = '';
  String _aadharBackUrl = '';

  bool _populated = false;

  @override
  void initState() {
    super.initState();
    context.read<OwnerKycCubit>().fetchDetails();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _dobCtrl.dispose();
    _panCtrl.dispose();
    _aadharCtrl.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic>? document) {
    if (_populated || document == null) return;
    _populated = true;
    _fullNameCtrl.text = (document['full_name'] ?? '').toString();
    _dobCtrl.text = (document['dob'] ?? '').toString();
    _panCtrl.text = (document['pan_number'] ?? '').toString();
    _aadharCtrl.text = (document['aadhar_number'] ?? '').toString();
    _panUrl = (document['pan_document'] ?? '').toString();
    _aadharFrontUrl = (document['aadhar_front'] ?? '').toString();
    _aadharBackUrl = (document['aadhar_back'] ?? '').toString();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dobCtrl.text) ??
        DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickImage(void Function(File) onPicked) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (file != null) {
      setState(() => onPicked(File(file.path)));
    }
  }

  void _submit(bool hasDocument) {
    final scheme = Theme.of(context).colorScheme;
    if (_fullNameCtrl.text.trim().isEmpty ||
        _dobCtrl.text.trim().isEmpty ||
        _panCtrl.text.trim().isEmpty ||
        _aadharCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fill in all fields.'),
        backgroundColor: scheme.error,
      ));
      return;
    }
    if (!hasDocument &&
        (_panFile == null ||
            _aadharFrontFile == null ||
            _aadharBackFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Please upload the PAN document, Aadhar front and Aadhar back.'),
        backgroundColor: scheme.error,
      ));
      return;
    }
    context.read<OwnerKycCubit>().submit(
          fullName: _fullNameCtrl.text.trim(),
          dob: _dobCtrl.text.trim(),
          panNumber: _panCtrl.text.trim(),
          aadharNumber: _aadharCtrl.text.trim(),
          panDocumentPath: _panFile?.path,
          aadharFrontPath: _aadharFrontFile?.path,
          aadharBackPath: _aadharBackFile?.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<OwnerKycCubit, OwnerKycState>(
      listener: (ctx, state) {
        if (state is OwnerKycLoaded) {
          _populate(state.document);
        }
        if (state is OwnerKycSubmitSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppDesignTokens.success,
          ));
        }
        if (state is OwnerKycError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: scheme.error,
          ));
        }
      },
      builder: (ctx, state) {
        return Scaffold(
          appBar: const SosAppBar(title: 'KYC Verification'),
          body: _body(ctx, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, OwnerKycState state) {
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

    if (state is OwnerKycLoaded) {
      return _loadedBody(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _loadedBody(BuildContext context, OwnerKycLoaded state) {
    final scheme = Theme.of(context).colorScheme;
    final document = state.document;
    final hasDocument = document != null;

    Widget banner;
    switch (state.status) {
      case 'approved':
        banner = _StatusBanner(
          color: AppDesignTokens.success,
          icon: Icons.verified_rounded,
          title: 'KYC Verified',
          subtitle: hasDocument
              ? null
              : 'Verified via your other SOS account role.',
        );
        break;
      case 'pending':
        banner = _StatusBanner(
          color: AppDesignTokens.warning,
          icon: Icons.hourglass_top_rounded,
          title: 'Your documents are under review.',
        );
        break;
      case 'rejected':
        final rejectionReason =
            (document?['rejection_reason'] as String?)?.trim();
        final subtitle = (rejectionReason != null && rejectionReason.isNotEmpty)
            ? rejectionReason
            : ((state.kycMessage?.trim().isNotEmpty ?? false)
                ? state.kycMessage!.trim()
                : 'Your documents were rejected. Please resubmit.');
        banner = _StatusBanner(
          color: scheme.error,
          icon: Icons.cancel_rounded,
          title: 'KYC Rejected',
          subtitle: subtitle,
        );
        break;
      default:
        banner = _StatusBanner(
          color: scheme.onSurfaceVariant,
          icon: Icons.info_outline_rounded,
          title: 'Complete KYC to enable wallet withdrawals.',
        );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          banner,
          SizedBox(height: 20.h),
          if (state.status == 'approved' && hasDocument)
            _readOnlyDetails(document)
          else
            _form(context, state),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _readOnlyDetails(Map<String, dynamic> document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _readOnlyRow('Full Name', (document['full_name'] ?? '').toString()),
        _readOnlyRow('Date of Birth', (document['dob'] ?? '').toString()),
        _readOnlyRow('PAN Number', (document['pan_number'] ?? '').toString()),
        _readOnlyRow(
            'Aadhar Number', (document['aadhar_number'] ?? '').toString()),
      ],
    );
  }

  Widget _readOnlyRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context, OwnerKycLoaded state) {
    final hasDocument = state.document != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PERSONAL DETAILS'),
        SizedBox(height: 10.h),
        SosTextField(
          label: 'Full Name',
          controller: _fullNameCtrl,
          prefixIcon: Icons.person_outline,
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(
            child: SosTextField(
              label: 'Date of Birth',
              controller: _dobCtrl,
              hint: 'YYYY-MM-DD',
              prefixIcon: Icons.calendar_today_outlined,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SosTextField(
          label: 'PAN Number',
          controller: _panCtrl,
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        SizedBox(height: 12.h),
        SosTextField(
          label: 'Aadhar Number',
          controller: _aadharCtrl,
          prefixIcon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 24.h),
        _sectionLabel('DOCUMENTS'),
        SizedBox(height: 10.h),
        _documentPicker(
          label: 'PAN Document',
          file: _panFile,
          existingUrl: _panUrl,
          onTap: () => _pickImage((f) => _panFile = f),
        ),
        SizedBox(height: 14.h),
        _documentPicker(
          label: 'Aadhar Front',
          file: _aadharFrontFile,
          existingUrl: _aadharFrontUrl,
          onTap: () => _pickImage((f) => _aadharFrontFile = f),
        ),
        SizedBox(height: 14.h),
        _documentPicker(
          label: 'Aadhar Back',
          file: _aadharBackFile,
          existingUrl: _aadharBackUrl,
          onTap: () => _pickImage((f) => _aadharBackFile = f),
        ),
        SizedBox(height: 28.h),
        SosButton(
          label: hasDocument ? 'Resubmit' : 'Submit for Verification',
          onPressed: () => _submit(hasDocument),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        color: scheme.primary,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _documentPicker({
    required String label,
    required File? file,
    required String existingUrl,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    Widget preview;
    if (file != null) {
      preview = Image.file(file, fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      preview = Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _documentPlaceholder(scheme),
      );
    } else {
      preview = _documentPlaceholder(scheme);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: double.infinity,
              height: 120.h,
              color: scheme.surfaceContainerHighest,
              child: preview,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPlaceholder(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_outlined,
              color: scheme.onSurfaceVariant, size: 26.r),
          SizedBox(height: 4.h),
          Text(
            'Tap to add',
            style: TextStyle(fontSize: 11.sp, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;

  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
