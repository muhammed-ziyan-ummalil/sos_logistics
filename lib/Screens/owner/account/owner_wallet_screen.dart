// Structural reuse of sosagent_flutter WalletScreen.
// Same: balance hero card, action row, transaction list, withdrawal sheet,
//       pending withdrawal card, KYC gate stub.
// Extended: escrow transaction type for logistics deliveries.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Bloc/OwnerWallet/owner_wallet_cubit.dart';
import '../../../Bloc/OwnerWallet/owner_wallet_state.dart';
import '../../../core/app_theme.dart';

class OwnerWalletScreen extends StatefulWidget {
  const OwnerWalletScreen({super.key});

  @override
  State<OwnerWalletScreen> createState() => _OwnerWalletScreenState();
}

class _OwnerWalletScreenState extends State<OwnerWalletScreen> {
  String _txFilter = 'all'; // all | escrow | withdrawal | credit | debit

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: Text('My Wallet',
            style: TextStyle(
                color: isDark
                    ? AppColors.textPrimary
                    : AppLightColors.textPrimary)),
        centerTitle: true,
      ),
      body: BlocConsumer<OwnerWalletCubit, OwnerWalletState>(
        listener: (ctx, state) {
          if (state is OwnerWalletActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor:
                  isDark ? AppColors.success : AppLightColors.success,
            ));
          } else if (state is OwnerWalletActionError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor:
                  isDark ? AppColors.error : AppLightColors.error,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is OwnerWalletLoading ||
              state is OwnerWalletInitial) {
            return Center(
              child: CircularProgressIndicator(
                  color: isDark ? AppColors.accent : AppLightColors.accent),
            );
          }
          if (state is OwnerWalletError) {
            return _ErrorView(
                message: state.message,
                isDark: isDark,
                onRetry: () =>
                    context.read<OwnerWalletCubit>().fetchWallet());
          }

          final loaded = state is OwnerWalletLoaded
              ? state
              : (state is OwnerWalletActionLoading ? state.data : null);
          if (loaded == null) return const SizedBox();

          final isActionLoading = state is OwnerWalletActionLoading;

          return RefreshIndicator(
            color: isDark ? AppColors.accent : AppLightColors.accent,
            backgroundColor:
                isDark ? AppColors.card : AppLightColors.card,
            onRefresh: () =>
                context.read<OwnerWalletCubit>().fetchWallet(),
            child: ListView(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                // ── Balance hero card ─────────────────────────────────
                _BalanceCard(
                  balance: loaded.balance,
                  isDark: isDark,
                  isLoading: isActionLoading,
                  onAddMoney: () => _showAddMoneySheet(isDark),
                  onWithdraw: loaded.pendingWithdrawal == null
                      ? () => _showWithdrawSheet(loaded.balance, isDark)
                      : null,
                ),
                SizedBox(height: 16.h),

                // ── Pending withdrawal card ───────────────────────────
                if (loaded.pendingWithdrawal != null)
                  _PendingWithdrawalCard(
                    withdrawal: loaded.pendingWithdrawal!,
                    isDark: isDark,
                    isLoading: isActionLoading,
                    onCancel: () => context
                        .read<OwnerWalletCubit>()
                        .cancelWithdrawal(loaded
                            .pendingWithdrawal!['id']?.toString() ??
                            ''),
                  ),
                if (loaded.pendingWithdrawal != null)
                  SizedBox(height: 16.h),

                // ── Transaction filter chips ──────────────────────────
                _FilterChips(
                  selected: _txFilter,
                  isDark: isDark,
                  onChanged: (f) => setState(() => _txFilter = f),
                ),
                SizedBox(height: 12.h),

                // ── Transaction list ──────────────────────────────────
                if (loaded.transactions.isEmpty)
                  _EmptyTransactions(isDark: isDark)
                else
                  ..._filteredTransactions(loaded.transactions)
                      .map((tx) => _TransactionTile(
                            tx: tx,
                            isDark: isDark,
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
            (tx['transaction_type'] as String? ?? '')
                    .toLowerCase() ==
                _txFilter)
        .toList();
  }

  // ── Add money sheet (Razorpay placeholder) ────────────────────────────────
  void _showAddMoneySheet(bool isDark) {
    final amountCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMoneySheet(
        isDark: isDark,
        controller: amountCtr,
        onConfirm: (amount) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Payment gateway integration pending. Amount: ₹$amount'),
              backgroundColor:
                  isDark ? AppColors.warning : AppLightColors.warning,
            ),
          );
        },
      ),
    );
  }

  // ── Withdraw sheet — same flow as agent app ───────────────────────────────
  void _showWithdrawSheet(double balance, bool isDark) {
    final amountCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(
        isDark: isDark,
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
// Balance card — reuses WalletHeroCard concept, adapted for AppColors
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onAddMoney;
  final VoidCallback? onWithdraw;

  const _BalanceCard({
    required this.balance,
    required this.isDark,
    required this.isLoading,
    required this.onAddMoney,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B3D91), Color(0xFF1A5DC8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtle top-right highlight circle
                const Text(
                  'Available Balance',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8.h),
                Text(
                  '₹${_fmt(balance)}',
                  style: const TextStyle(
                    color: Colors.white,
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
                      child: _CardActionBtn(
                        icon: Icons.add_rounded,
                        label: 'Add Money',
                        onTap: isLoading ? null : onAddMoney,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _CardActionBtn(
                        icon: Icons.arrow_upward_rounded,
                        label: onWithdraw == null
                            ? 'Request Pending'
                            : 'Withdraw',
                        onTap: isLoading ? null : onWithdraw,
                        muted: onWithdraw == null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Decorative radial highlight
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
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

class _CardActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool muted;

  const _CardActionBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: muted
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14.r,
                color: muted
                    ? Colors.white54
                    : Colors.white),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: muted ? Colors.white54 : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending withdrawal card
// ─────────────────────────────────────────────────────────────────────────────
class _PendingWithdrawalCard extends StatelessWidget {
  final Map<String, dynamic> withdrawal;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onCancel;

  const _PendingWithdrawalCard({
    required this.withdrawal,
    required this.isDark,
    required this.isLoading,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final amount = withdrawal['amount']?.toString() ?? '—';
    final status = (withdrawal['status'] as String? ?? 'pending')
        .toUpperCase();
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final warningColor =
        isDark ? AppColors.warning : AppLightColors.warning;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: warningColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.hourglass_top_rounded,
                color: warningColor, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdrawal Request',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Text('₹$amount · $status',
                    style: TextStyle(
                        fontSize: 11.sp, color: textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: Text('Cancel',
                style: TextStyle(
                    fontSize: 12.sp, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.selected,
    required this.isDark,
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
    final primaryColor =
        isDark ? AppColors.primaryLight : AppLightColors.primary;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

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
                      ? primaryColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: isSelected
                          ? primaryColor.withOpacity(0.4)
                          : dividerColor),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected ? primaryColor : textSecondary,
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
// Transaction tile
// Reuses TransactionRow concept from app_design_system, adapted to AppColors.
// Adds escrow type for logistics deliveries.
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool isDark;

  const _TransactionTile({required this.tx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type =
        (tx['type'] ?? tx['transaction_type'] ?? '') as String;
    final isCredit = tx['credit_debit'] == 'credit' ||
        tx['amount_type'] == 'credit' ||
        type == 'escrow_release' ||
        type == 'credit';
    final isEscrow = type.contains('escrow');

    final amount = tx['amount']?.toString() ?? '0';
    final title = _title(type, tx);
    final meta = tx['created_at'] as String? ??
        tx['date'] as String? ??
        '';

    final primaryColor =
        isDark ? AppColors.primaryLight : AppLightColors.primary;
    final debitColor = isDark ? AppColors.error : AppLightColors.error;
    final escrowColor = isDark ? AppColors.warning : AppLightColors.warning;
    final cardColor = isDark ? AppColors.card : AppLightColors.card;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    final iconColor = isEscrow
        ? escrowColor
        : isCredit
            ? primaryColor
            : debitColor;
    final amountColor = isEscrow
        ? escrowColor
        : isCredit
            ? primaryColor
            : debitColor;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding:
          EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        border:
            Border(bottom: BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8.r),
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
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary)),
                Text(meta,
                    style: TextStyle(
                        fontSize: 11.sp, color: textSecondary)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹$amount',
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
// Add Money sheet (Razorpay placeholder)
// ─────────────────────────────────────────────────────────────────────────────
class _AddMoneySheet extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onConfirm;

  const _AddMoneySheet({
    required this.isDark,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: surfaceColor,
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
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2.r))),
            ),
            SizedBox(height: 16.h),
            Text('Add Money',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            Text('Enter amount to add to your wallet',
                style:
                    TextStyle(fontSize: 13.sp, color: textSecondary)),
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
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text('₹$v',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color: textPrimary, fontSize: 15.sp),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            SizedBox(height: 20.h),
            // Razorpay placeholder banner
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16.r, color: AppColors.warning),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Payment gateway (Razorpay) integration pending.',
                      style: TextStyle(
                          fontSize: 11.sp, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) return;
                  onConfirm(v);
                },
                child: const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdraw sheet — same multi-step logic as agent app
// ─────────────────────────────────────────────────────────────────────────────
class _WithdrawSheet extends StatelessWidget {
  final bool isDark;
  final double balance;
  final TextEditingController controller;
  final ValueChanged<double> onConfirm;

  const _WithdrawSheet({
    required this.isDark,
    required this.balance,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.surface : AppLightColors.surface;
    final dividerColor =
        isDark ? AppColors.divider : AppLightColors.divider;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: surfaceColor,
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
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2.r))),
            ),
            SizedBox(height: 16.h),
            Text('Withdraw Funds',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            Text(
                'Available: ₹${balance.toStringAsFixed(2)} · Credit within 24 hours',
                style:
                    TextStyle(fontSize: 12.sp, color: textSecondary)),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textPrimary, fontSize: 15.sp),
              decoration: const InputDecoration(
                labelText: 'Withdrawal Amount',
                prefixText: '₹ ',
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_outlined,
                      size: 16.r, color: AppColors.primaryLight),
                  SizedBox(width: 8.w),
                  Text('Amount will be sent to your registered bank account.',
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.primaryLight)),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount =
                      double.tryParse(controller.text.trim());
                  if (amount == null || amount <= 0) return;
                  if (amount > balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Amount exceeds available balance.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  onConfirm(amount);
                },
                child: const Text('Submit Withdrawal Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorView(
      {required this.message,
      required this.isDark,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: isDark ? AppColors.error : AppLightColors.error,
                size: 40.r),
            SizedBox(height: 12.h),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                    fontSize: 13.sp)),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final bool isDark;
  const _EmptyTransactions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 40.r,
                color: isDark
                    ? AppColors.divider
                    : AppLightColors.divider),
            SizedBox(height: 12.h),
            Text('No transactions yet',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                    fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }
}
