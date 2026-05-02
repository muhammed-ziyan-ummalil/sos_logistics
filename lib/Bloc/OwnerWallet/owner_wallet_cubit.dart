import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'owner_wallet_state.dart';

class OwnerWalletCubit extends Cubit<OwnerWalletState> {
  OwnerWalletCubit() : super(OwnerWalletInitial());

  Future<void> fetchWallet() async {
    emit(OwnerWalletLoading());
    final res = await ApiServiceV2.instance.get('owner/wallet');
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final balance =
          double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
      final rawTx = (data['transactions'] as List?) ?? [];
      final transactions =
          rawTx.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final pendingWithdrawal = data['pending_withdrawal'] != null
          ? Map<String, dynamic>.from(data['pending_withdrawal'] as Map)
          : null;
      emit(OwnerWalletLoaded(
        balance: balance,
        transactions: transactions,
        pendingWithdrawal: pendingWithdrawal,
      ));
    } else {
      final msg = res['message'] as String? ?? '';
      // Endpoint not deployed yet — show empty wallet rather than error screen
      if (msg.contains("Can't find a route") ||
          msg.contains('404') ||
          msg.toLowerCase().contains('not found') ||
          msg.toLowerCase().contains('no route')) {
        emit(OwnerWalletLoaded(
          balance: 0.0,
          transactions: [],
          pendingWithdrawal: null,
        ));
      } else {
        emit(OwnerWalletError(
            msg.isEmpty ? 'Failed to load wallet.' : msg));
      }
    }
  }

  Future<void> requestWithdrawal(double amount) async {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(OwnerWalletActionLoading(loaded));
    final res = await ApiServiceV2.instance
        .post('owner/wallet/withdraw', data: {'amount': amount.toString()});
    if (res['status'] == 'success') {
      emit(OwnerWalletActionSuccess('Withdrawal request submitted.'));
      await fetchWallet();
    } else {
      emit(OwnerWalletActionError(
        message: res['message'] as String? ?? 'Failed to submit withdrawal.',
        data: loaded,
      ));
      emit(loaded);
    }
  }

  Future<void> cancelWithdrawal(String withdrawalId) async {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(OwnerWalletActionLoading(loaded));
    final res = await ApiServiceV2.instance
        .post('owner/wallet/withdraw/$withdrawalId/cancel', data: {});
    if (res['status'] == 'success') {
      emit(OwnerWalletActionSuccess('Withdrawal request cancelled.'));
      await fetchWallet();
    } else {
      emit(OwnerWalletActionError(
        message: res['message'] as String? ?? 'Failed to cancel withdrawal.',
        data: loaded,
      ));
      emit(loaded);
    }
  }

  OwnerWalletLoaded? get _loaded {
    final s = state;
    if (s is OwnerWalletLoaded) return s;
    if (s is OwnerWalletActionLoading) return s.data;
    if (s is OwnerWalletActionError) return s.data;
    return null;
  }
}
