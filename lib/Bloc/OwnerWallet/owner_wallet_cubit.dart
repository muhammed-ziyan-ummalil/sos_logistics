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
      emit(OwnerWalletLoaded(
        balance: balance,
        transactions: transactions,
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
        ));
      } else {
        emit(OwnerWalletError(
            msg.isEmpty ? 'Failed to load wallet.' : msg));
      }
    }
  }

  /// Test-mode top-up (no real gateway yet). Credits the wallet on the backend
  /// then refreshes the balance/transactions. Returns null on success, or the
  /// error message on failure (the screen shows it without leaving the wallet).
  Future<String?> addCash(double amount) async {
    if (amount <= 0) return 'A valid amount is required.';
    final res = await ApiServiceV2.instance.post(
      'owner/wallet/add-cash',
      data: {'amount': amount.toString()},
    );
    if (res['status'] == 'success') {
      await fetchWallet();
      return null;
    }
    return res['message'] as String? ?? 'Could not add cash to wallet.';
  }
}
