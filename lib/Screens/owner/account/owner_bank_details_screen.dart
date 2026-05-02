// Structural reuse of sosagent_flutter AddBankDetails screen.
// Same fields: bank name, account number, account holder name, IFSC code.
// Uses ApiServiceV2 + OwnerBankDetailsCubit.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerBankDetails/owner_bank_details_cubit.dart';
import '../../../Bloc/OwnerBankDetails/owner_bank_details_state.dart';
import '../../../core/app_theme.dart';

class OwnerBankDetailsScreen extends StatefulWidget {
  const OwnerBankDetailsScreen({super.key});

  @override
  State<OwnerBankDetailsScreen> createState() =>
      _OwnerBankDetailsScreenState();
}

class _OwnerBankDetailsScreenState
    extends State<OwnerBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtr = TextEditingController();
  final _accountNumberCtr = TextEditingController();
  final _holderNameCtr = TextEditingController();
  final _ifscCtr = TextEditingController();

  @override
  void dispose() {
    _bankNameCtr.dispose();
    _accountNumberCtr.dispose();
    _holderNameCtr.dispose();
    _ifscCtr.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> d) {
    _bankNameCtr.text = d['bank_name'] as String? ?? '';
    _accountNumberCtr.text = d['account_number'] as String? ?? '';
    _holderNameCtr.text =
        d['account_holder_name'] as String? ?? '';
    _ifscCtr.text = d['ifsc_code'] as String? ?? '';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<OwnerBankDetailsCubit>().saveDetails(
          bankName: _bankNameCtr.text.trim(),
          accountNumber: _accountNumberCtr.text.trim(),
          accountHolderName: _holderNameCtr.text.trim(),
          ifscCode: _ifscCtr.text.trim().toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OwnerBankDetailsCubit, OwnerBankDetailsState>(
      listener: (ctx, state) {
        if (state is OwnerBankDetailsLoaded) {
          _populate(state.details);
        }
        if (state is OwnerBankDetailsSaved) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: const Text('Bank details saved.'),
            backgroundColor:
                isDark ? AppColors.success : AppLightColors.success,
          ));
        }
        if (state is OwnerBankDetailsSaveError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor:
                isDark ? AppColors.error : AppLightColors.error,
          ));
        }
      },
      builder: (ctx, state) {
        final isSaving = state is OwnerBankDetailsSaving;
        final isLoading = state is OwnerBankDetailsLoading ||
            state is OwnerBankDetailsInitial;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.background : AppLightColors.background,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.surface : AppLightColors.surface,
            leading: BackButton(
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary),
            title: Text('Bank Details',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppLightColors.textPrimary)),
            centerTitle: true,
          ),
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: isDark
                          ? AppColors.accent
                          : AppLightColors.accent))
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 16.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info banner
                        _InfoBanner(isDark: isDark),
                        SizedBox(height: 20.h),

                        _label('BANK INFORMATION', isDark),
                        SizedBox(height: 10.h),

                        _field(
                          controller: _bankNameCtr,
                          label: 'Bank Name',
                          icon: Icons.account_balance_outlined,
                          isDark: isDark,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Bank name is required'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        _field(
                          controller: _accountNumberCtr,
                          label: 'Account Number',
                          icon: Icons.credit_card_rounded,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) {
                              return 'Account number is required';
                            }
                            if ((v?.trim().length ?? 0) < 8) {
                              return 'Enter a valid account number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        _field(
                          controller: _holderNameCtr,
                          label: 'Account Holder Name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Account holder name is required'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        _field(
                          controller: _ifscCtr,
                          label: 'IFSC Code',
                          icon: Icons.tag_rounded,
                          isDark: isDark,
                          textCapitalization:
                              TextCapitalization.characters,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) {
                              return 'IFSC code is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32.h),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _submit,
                            child: isSaving
                                ? SizedBox(
                                    height: 20.r,
                                    width: 20.r,
                                    child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : const Text('Save Bank Details'),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.accent : AppLightColors.accent,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
          fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            color: isDark
                ? AppColors.textSecondary
                : AppLightColors.textSecondary),
      ),
      validator: validator,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isDark;
  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.accent : AppLightColors.accent;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10.r),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Bank details are used for withdrawal payouts. Ensure the account belongs to you.',
              style: TextStyle(fontSize: 11.sp, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
