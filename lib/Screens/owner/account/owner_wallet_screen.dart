// Structural reuse of sosagent_flutter WalletScreen.
// Statement view: balance hero card, transaction list, filter chips.
// Withdrawals are handled on the dedicated OwnerWithdrawals screen.
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
      body: BlocBuilder<OwnerWalletCubit, OwnerWalletState>(
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

          final loaded = state is OwnerWalletLoaded ? state : null;
          if (loaded == null) return const SizedBox();

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
                  onAddMoney: () => _showAddMoneySheet(),
                ),
                SizedBox(height: 16.h),

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

  // ── Add money sheet ───────────────────────────────────────────────────────
  // Test-mode top-up: credits the wallet on the backend and refreshes. Swap the
  // cubit.addCash call for a real payment-gateway flow when the gateway is live.
  void _showAddMoneySheet() {
    final cubit = context.read<OwnerWalletCubit>();
    final amountCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMoneySheet(
        controller: amountCtr,
        onConfirm: (amount) async {
          Navigator.pop(context);
          final parsed = double.tryParse(amount.trim()) ?? 0;
          if (parsed <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Enter a valid amount.'),
                backgroundColor: AppDesignTokens.warning,
              ),
            );
            return;
          }
          final error = await cubit.addCash(parsed);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ??
                  'Added ${AppConstants.currencySymbol}${parsed.toStringAsFixed(0)} to your wallet.'),
              backgroundColor:
                  error == null ? AppDesignTokens.success : AppDesignTokens.warning,
            ),
          );
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
  final VoidCallback onAddMoney;

  const _EmeraldBalanceCard({
    required this.balance,
    required this.onAddMoney,
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
          OutlinedButton.icon(
            onPressed: onAddMoney,
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
              minimumSize: Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusXS)),
            ),
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
      'delivery_compensation_hold' => 'Compensation Deposit Held',
      'delivery_compensation_refund' => 'Compensation Deposit Refunded',
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
      'delivery_compensation_hold' => Icons.shield_outlined,
      'delivery_compensation_refund' => Icons.undo_rounded,
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
