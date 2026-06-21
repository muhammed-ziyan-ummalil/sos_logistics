// Structural reuse of sosagent_flutter AddBankDetails screen.
// Same fields: bank name, account number, account holder name, IFSC code.
// Uses ApiServiceV2 + OwnerBankDetailsCubit.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerBankDetails/owner_bank_details_cubit.dart';
import '../../../Bloc/OwnerBankDetails/owner_bank_details_state.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<OwnerBankDetailsCubit, OwnerBankDetailsState>(
      listener: (ctx, state) {
        if (state is OwnerBankDetailsLoaded) {
          _populate(state.details);
        }
        if (state is OwnerBankDetailsSaved) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: const Text('Bank details saved.'),
            backgroundColor: AppDesignTokens.success,
          ));
          context.read<OwnerBankDetailsCubit>().fetchDetails();
        }
        if (state is OwnerBankDetailsSaveError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: scheme.error,
          ));
        }
      },
      builder: (ctx, state) {
        final isSaving = state is OwnerBankDetailsSaving;
        final isLoading = state is OwnerBankDetailsLoading ||
            state is OwnerBankDetailsInitial;

        return Scaffold(
          appBar: const SosAppBar(title: 'Bank Details'),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 16.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info banner
                        _InfoBanner(),
                        SizedBox(height: 20.h),

                        _label('BANK INFORMATION', scheme),
                        SizedBox(height: 10.h),

                        SosTextField(
                          label: 'Bank Name',
                          controller: _bankNameCtr,
                          prefixIcon: Icons.account_balance_outlined,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Bank name is required'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        SosTextField(
                          label: 'Account Number',
                          controller: _accountNumberCtr,
                          prefixIcon: Icons.credit_card_rounded,
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
                        SosTextField(
                          label: 'Account Holder Name',
                          controller: _holderNameCtr,
                          prefixIcon: Icons.person_outline,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Account holder name is required'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        SosTextField(
                          label: 'IFSC Code',
                          controller: _ifscCtr,
                          prefixIcon: Icons.tag_rounded,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) {
                              return 'IFSC code is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32.h),

                        SosButton(
                          label: 'Save',
                          loading: isSaving,
                          onPressed: isSaving ? null : _submit,
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

  Widget _label(String text, ColorScheme scheme) {
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
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
