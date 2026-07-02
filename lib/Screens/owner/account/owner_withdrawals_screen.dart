// Withdraw / earnings screen for vehicle owners.
// Shows wallet balance (from owner/withdrawals), lets the owner request a
// withdrawal, lists past requests with their status, and allows cancelling a
// pending request. Nudges the owner to add bank details first when missing.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerBankDetails/owner_bank_details_cubit.dart';
import '../../../Bloc/OwnerWithdrawals/owner_withdrawals_cubit.dart';
import '../../../Bloc/OwnerWithdrawals/owner_withdrawals_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';
import 'owner_bank_details_screen.dart';

class OwnerWithdrawalsScreen extends StatefulWidget {
  /// Whether the owner already has bank details on file. When false, the
  /// screen surfaces a nudge to add them before withdrawing.
  final bool hasBankDetails;

  const OwnerWithdrawalsScreen({super.key, this.hasBankDetails = true});

  @override
  State<OwnerWithdrawalsScreen> createState() =>
      _OwnerWithdrawalsScreenState();
}

class _OwnerWithdrawalsScreenState extends State<OwnerWithdrawalsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const SosAppBar(title: 'Withdraw', centerTitle: true),
      body: BlocConsumer<OwnerWithdrawalsCubit, OwnerWithdrawalsState>(
        listener: (ctx, state) {
          if (state is OwnerWithdrawalsActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppDesignTokens.success,
            ));
          } else if (state is OwnerWithdrawalsActionError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: scheme.error,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is OwnerWithdrawalsLoading ||
              state is OwnerWithdrawalsInitial) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  SkeletonBox(
                      width: double.infinity,
                      height: 140.h,
                      radius: AppDesignTokens.radiusCard),
                  SizedBox(height: 16.h),
                  ...List.generate(
                    4,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child:
                          SkeletonBox(width: double.infinity, height: 60.h),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is OwnerWithdrawalsError) {
            return ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<OwnerWithdrawalsCubit>().fetchWithdrawals(),
            );
          }

          final loaded = state is OwnerWithdrawalsLoaded
              ? state
              : (state is OwnerWithdrawalsActionLoading ? state.data : null);
          if (loaded == null) return const SizedBox();

          final isActionLoading = state is OwnerWithdrawalsActionLoading;
          final hasPending = loaded.requests.any(
              (r) => (r['status'] as String? ?? '').toLowerCase() == 'pending');

          return RefreshIndicator(
            color: scheme.primary,
            backgroundColor: scheme.surface,
            onRefresh: () =>
                context.read<OwnerWithdrawalsCubit>().fetchWithdrawals(),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                // ── Balance hero card ─────────────────────────────────
                _BalanceCard(
                  balance: loaded.balance,
                  isLoading: isActionLoading,
                  onWithdraw: hasPending
                      ? null
                      : () => _onWithdrawTap(loaded.balance),
                ),
                SizedBox(height: 16.h),

                // ── Bank details nudge ────────────────────────────────
                if (!widget.hasBankDetails) ...[
                  _BankDetailsNudge(onTap: _openBankDetails),
                  SizedBox(height: 16.h),
                ],

                // ── Requests header ───────────────────────────────────
                Text(
                  'WITHDRAWAL REQUESTS',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 10.h),

                // ── Requests list ─────────────────────────────────────
                if (loaded.requests.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No withdrawal requests yet',
                    subtitle: 'Your withdrawal requests will appear here.',
                  )
                else
                  ...loaded.requests.map((r) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _RequestTile(
                          request: r,
                          isLoading: isActionLoading,
                          onCancel: () {
                            final id = int.tryParse(r['id']?.toString() ?? '');
                            if (id == null) return;
                            context
                                .read<OwnerWithdrawalsCubit>()
                                .cancelWithdrawal(id);
                          },
                        ),
                      )),

                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onWithdrawTap(double balance) {
    if (!widget.hasBankDetails) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Add your bank details before withdrawing.'),
        backgroundColor: AppDesignTokens.warning,
      ));
      _openBankDetails();
      return;
    }
    _showWithdrawSheet(balance);
  }

  Future<void> _openBankDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OwnerBankDetailsCubit()..fetchDetails(),
          child: const OwnerBankDetailsScreen(),
        ),
      ),
    );
  }

  void _showWithdrawSheet(double balance) {
    final amountCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(
        balance: balance,
        controller: amountCtr,
        onConfirm: (amount) {
          Navigator.pop(context);
          context.read<OwnerWithdrawalsCubit>().requestWithdrawal(amount);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance hero card
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final bool isLoading;
  final VoidCallback? onWithdraw;

  const _BalanceCard({
    required this.balance,
    required this.isLoading,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, AppDesignTokens.lightPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        boxShadow: AppDesignTokens.walletGlow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.80),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6.h),
          Text(
            '${AppConstants.currencySymbol}${balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onWithdraw,
              icon: Icon(Icons.arrow_upward_rounded,
                  size: 16.r,
                  color: onWithdraw == null
                      ? scheme.onPrimary.withValues(alpha: 0.45)
                      : scheme.onPrimary),
              label: Text(
                onWithdraw == null ? 'Request Pending' : 'Request Withdrawal',
                style: TextStyle(
                    color: onWithdraw == null
                        ? scheme.onPrimary.withValues(alpha: 0.45)
                        : scheme.onPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: scheme.onPrimary
                        .withValues(alpha: onWithdraw == null ? 0.20 : 0.35)),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusXS)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank details nudge — shown when the owner has no bank details on file
// ─────────────────────────────────────────────────────────────────────────────
class _BankDetailsNudge extends StatelessWidget {
  final VoidCallback onTap;

  const _BankDetailsNudge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppDesignTokens.warning;
    return SosCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusXS),
            ),
            child: Icon(Icons.account_balance_outlined,
                color: color, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add bank details',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 13.sp)),
                Text('Required to receive withdrawal payouts.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18.r, color: Theme.of(context).colorScheme.outline),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdrawal request tile — status badge + cancel on pending
// ─────────────────────────────────────────────────────────────────────────────
class _RequestTile extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isLoading;
  final VoidCallback onCancel;

  const _RequestTile({
    required this.request,
    required this.isLoading,
    required this.onCancel,
  });

  SosTone _tone(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return SosTone.warning;
      case 'processed':
      case 'paid':
      case 'completed':
        return SosTone.success;
      case 'cancelled':
      case 'rejected':
        return SosTone.error;
      default:
        return SosTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = (request['status'] as String? ?? 'pending');
    final isPending = status.toLowerCase() == 'pending';
    final amount = request['amount']?.toString() ?? '0';
    final requestId = request['request_id']?.toString() ??
        request['id']?.toString() ??
        '';
    final created = request['created_at'] as String? ?? '';
    final txnId = request['transaction_id']?.toString();

    return SosCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppConstants.currencySymbol}$amount',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SosChip(label: status.toUpperCase(), tone: _tone(status)),
            ],
          ),
          if (requestId.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text('Ref: $requestId',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (created.isNotEmpty)
            Text(created, style: Theme.of(context).textTheme.bodySmall),
          if (txnId != null && txnId.isNotEmpty)
            Text('Txn: $txnId',
                style: Theme.of(context).textTheme.bodySmall),
          if (isPending) ...[
            SizedBox(height: 4.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onCancel,
                child: Text('Cancel',
                    style: TextStyle(fontSize: 12.sp, color: scheme.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdraw sheet — theme-aware
// ─────────────────────────────────────────────────────────────────────────────
class _WithdrawSheet extends StatelessWidget {
  final double balance;
  final TextEditingController controller;
  final ValueChanged<double> onConfirm;

  const _WithdrawSheet({
    required this.balance,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
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
                      borderRadius: BorderRadius.circular(2.r))),
            ),
            SizedBox(height: 16.h),
            Text('Withdraw Funds',
                style: textTheme.titleLarge?.copyWith(fontSize: 16.sp)),
            Text(
                'Available: ${AppConstants.currencySymbol}${balance.toStringAsFixed(2)} · Credit within 24 hours',
                style: textTheme.bodySmall),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Withdrawal Amount',
                prefixText: '${AppConstants.currencySymbol} ',
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusXS),
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_outlined,
                      size: 16.r, color: scheme.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Amount will be sent to your registered bank account.',
                      style: TextStyle(
                          fontSize: 11.sp, color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SosButton(
              label: 'Submit Withdrawal Request',
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());
                if (amount == null || amount <= 0) return;
                if (amount > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Amount exceeds available balance.'),
                      backgroundColor: scheme.error,
                    ),
                  );
                  return;
                }
                onConfirm(amount);
              },
            ),
          ],
        ),
      ),
    );
  }
}
