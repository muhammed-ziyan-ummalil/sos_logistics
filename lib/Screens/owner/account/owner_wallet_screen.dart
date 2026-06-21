// Structural reuse of sosagent_flutter WalletScreen.
// Same: balance hero card, action row, transaction list, withdrawal sheet,
//       pending withdrawal card, KYC gate stub.
// Extended: escrow transaction type for logistics deliveries.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerWallet/owner_wallet_cubit.dart';
import '../../../Bloc/OwnerWallet/owner_wallet_state.dart';
import '../../../core/app_constants.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/widgets.dart';

class OwnerWalletScreen extends StatefulWidget {
  const OwnerWalletScreen({super.key});

  @override
  State<OwnerWalletScreen> createState() => _OwnerWalletScreenState();
}

class _OwnerWalletScreenState extends State<OwnerWalletScreen> {
  String _txFilter = 'all'; // all | escrow | withdrawal | credit | debit

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const SosAppBar(title: 'My Wallet', centerTitle: true),
      body: BlocConsumer<OwnerWalletCubit, OwnerWalletState>(
        listener: (ctx, state) {
          if (state is OwnerWalletActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppDesignTokens.success,
            ));
          } else if (state is OwnerWalletActionError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: scheme.error,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is OwnerWalletLoading || state is OwnerWalletInitial) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  SkeletonBox(width: double.infinity, height: 140.h, radius: AppDesignTokens.radiusCard),
                  SizedBox(height: 16.h),
                  SkeletonBox(width: double.infinity, height: 44.h),
                  SizedBox(height: 12.h),
                  ...List.generate(5, (_) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: SkeletonBox(width: double.infinity, height: 60.h),
                  )),
                ],
              ),
            );
          }
          if (state is OwnerWalletError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<OwnerWalletCubit>().fetchWallet(),
            );
          }

          final loaded = state is OwnerWalletLoaded
              ? state
              : (state is OwnerWalletActionLoading ? state.data : null);
          if (loaded == null) return const SizedBox();

          final isActionLoading = state is OwnerWalletActionLoading;

          return RefreshIndicator(
            color: scheme.primary,
            backgroundColor: scheme.surface,
            onRefresh: () => context.read<OwnerWalletCubit>().fetchWallet(),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                // ── Balance hero card ─────────────────────────────────
                _EmeraldBalanceCard(
                  balance: loaded.balance,
                  isLoading: isActionLoading,
                  onAddMoney: () => _showAddMoneySheet(),
                  onWithdraw: loaded.pendingWithdrawal == null
                      ? () => _showWithdrawSheet(loaded.balance)
                      : null,
                ),
                SizedBox(height: 16.h),

                // ── Pending withdrawal card ───────────────────────────
                if (loaded.pendingWithdrawal != null)
                  _PendingWithdrawalCard(
                    withdrawal: loaded.pendingWithdrawal!,
                    isLoading: isActionLoading,
                    onCancel: () => context
                        .read<OwnerWalletCubit>()
                        .cancelWithdrawal(
                            loaded.pendingWithdrawal!['id']?.toString() ?? ''),
                  ),
                if (loaded.pendingWithdrawal != null) SizedBox(height: 16.h),

                // ── Transaction filter chips ──────────────────────────
                _FilterChips(
                  selected: _txFilter,
                  onChanged: (f) => setState(() => _txFilter = f),
                ),
                SizedBox(height: 12.h),

                // ── Transaction list ──────────────────────────────────
                if (loaded.transactions.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions yet',
                    subtitle: 'Your wallet transactions will appear here.',
                  )
                else
                  ..._filteredTransactions(loaded.transactions)
                      .map((tx) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: _TransactionTile(tx: tx),
                          )),

                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filteredTransactions(
      List<Map<String, dynamic>> all) {
    if (_txFilter == 'all') return all;
    return all
        .where((tx) =>
            (tx['type'] as String? ?? '').toLowerCase() == _txFilter ||
            (tx['transaction_type'] as String? ?? '').toLowerCase() ==
                _txFilter)
        .toList();
  }

  // ── Add money sheet (Razorpay placeholder) ────────────────────────────────
  void _showAddMoneySheet() {
    final amountCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMoneySheet(
        controller: amountCtr,
        onConfirm: (amount) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Payment gateway integration pending. Amount: ${AppConstants.currencySymbol}$amount'),
              backgroundColor: AppDesignTokens.warning,
            ),
          );
        },
      ),
    );
  }

  // ── Withdraw sheet ────────────────────────────────────────────────────────
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
          context.read<OwnerWalletCubit>().requestWithdrawal(amount);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Emerald balance hero card (replaces navy gradient _BalanceCard)
// ─────────────────────────────────────────────────────────────────────────────
class _EmeraldBalanceCard extends StatelessWidget {
  final double balance;
  final bool isLoading;
  final VoidCallback onAddMoney;
  final VoidCallback? onWithdraw;

  const _EmeraldBalanceCard({
    required this.balance,
    required this.isLoading,
    required this.onAddMoney,
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
            '${AppConstants.currencySymbol}${_fmt(balance)}',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onAddMoney,
                  icon: Icon(Icons.add_rounded, size: 16.r,
                      color: scheme.onPrimary),
                  label: Text('Add Money',
                      style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: scheme.onPrimary.withValues(alpha: 0.35)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusXS)),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onWithdraw,
                  icon: Icon(Icons.arrow_upward_rounded, size: 16.r,
                      color: onWithdraw == null
                          ? scheme.onPrimary.withValues(alpha: 0.45)
                          : scheme.onPrimary),
                  label: Text(
                    onWithdraw == null ? 'Request Pending' : 'Withdraw',
                    style: TextStyle(
                        color: onWithdraw == null
                            ? scheme.onPrimary.withValues(alpha: 0.45)
                            : scheme.onPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: scheme.onPrimary.withValues(
                            alpha: onWithdraw == null ? 0.20 : 0.35)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusXS)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}K';
    return v.toStringAsFixed(2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending withdrawal card
// ─────────────────────────────────────────────────────────────────────────────
class _PendingWithdrawalCard extends StatelessWidget {
  final Map<String, dynamic> withdrawal;
  final bool isLoading;
  final VoidCallback onCancel;

  const _PendingWithdrawalCard({
    required this.withdrawal,
    required this.isLoading,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = withdrawal['amount']?.toString() ?? '—';
    final status =
        (withdrawal['status'] as String? ?? 'pending').toUpperCase();

    return SosCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppDesignTokens.warning.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusXS),
            ),
            child: Icon(Icons.hourglass_top_rounded,
                color: AppDesignTokens.warning, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdrawal Request',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 13.sp)),
                Text(
                    '${AppConstants.currencySymbol}$amount · $status',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: Text('Cancel',
                style: TextStyle(fontSize: 12.sp, color: scheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips — SosChip-based selectable row
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.selected,
    required this.onChanged,
  });

  static const _filters = [
    ('all', 'All'),
    ('escrow', 'Escrow'),
    ('withdrawal', 'Withdrawal'),
    ('credit', 'Credits'),
    ('debit', 'Debits'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.45)
                          : scheme.outline),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? scheme.primary
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction tile — SosCard-wrapped
// Adds escrow type for logistics deliveries.
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type =
        (tx['type'] ?? tx['transaction_type'] ?? '') as String;
    final isCredit = tx['credit_debit'] == 'credit' ||
        tx['amount_type'] == 'credit' ||
        type == 'escrow_release' ||
        type == 'credit';
    final isEscrow = type.contains('escrow');

    final amount = tx['amount']?.toString() ?? '0';
    final title = _title(type, tx);
    final meta = tx['created_at'] as String? ?? tx['date'] as String? ?? '';

    final iconColor = isEscrow
        ? AppDesignTokens.warning
        : isCredit
            ? AppDesignTokens.success
            : scheme.error;
    final amountColor = iconColor;

    return SosCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusXS),
            ),
            child: Icon(
              _icon(type, isCredit),
              size: 16.r,
              color: iconColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 13.sp)),
                Text(meta,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${AppConstants.currencySymbol}$amount',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: amountColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _title(String type, Map<String, dynamic> tx) {
    return switch (type.toLowerCase()) {
      'escrow_hold' => 'Delivery Escrow Hold',
      'escrow_release' => 'Delivery Escrow Released',
      'escrow_refund' => 'Escrow Refunded',
      'withdrawal' => 'Withdrawal Request',
      'withdrawal_paid' => 'Withdrawal Paid',
      'credit' => tx['remark'] as String? ?? 'Credit',
      'debit' => tx['remark'] as String? ?? 'Debit',
      _ => tx['remark'] as String? ??
          type.replaceAll('_', ' ').toUpperCase(),
    };
  }

  IconData _icon(String type, bool isCredit) {
    return switch (type.toLowerCase()) {
      'escrow_hold' => Icons.lock_outline_rounded,
      'escrow_release' => Icons.lock_open_rounded,
      'escrow_refund' => Icons.undo_rounded,
      'withdrawal' || 'withdrawal_paid' => Icons.arrow_upward_rounded,
      _ => isCredit
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Money sheet (Razorpay placeholder) — theme-aware
// ─────────────────────────────────────────────────────────────────────────────
class _AddMoneySheet extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onConfirm;

  const _AddMoneySheet({
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20.r)),
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
            Text('Add Money',
                style: textTheme.titleLarge?.copyWith(fontSize: 16.sp)),
            Text('Enter amount to add to your wallet',
                style: textTheme.bodySmall),
            SizedBox(height: 16.h),
            // Quick amount chips
            Wrap(
              spacing: 8.w,
              children: ['500', '1000', '2000', '5000'].map((v) {
                return GestureDetector(
                  onTap: () => controller.text = v,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color:
                          scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: scheme.primary
                              .withValues(alpha: 0.25)),
                    ),
                    child: Text(
                        '${AppConstants.currencySymbol}$v',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: scheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${AppConstants.currencySymbol} ',
              ),
            ),
            SizedBox(height: 20.h),
            // Razorpay placeholder banner
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppDesignTokens.warning.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusXS),
                border: Border.all(
                    color:
                        AppDesignTokens.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16.r, color: AppDesignTokens.warning),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Payment gateway (Razorpay) integration pending.',
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: AppDesignTokens.warning),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SosButton(
              label: 'Continue to Payment',
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) return;
                onConfirm(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdraw sheet — theme-aware (same onConfirm behavior)
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20.r)),
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
                      content: const Text(
                          'Amount exceeds available balance.'),
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
