import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import 'owner_withdrawals_state.dart';

class OwnerWithdrawalsCubit extends Cubit<OwnerWithdrawalsState> {
  OwnerWithdrawalsCubit() : super(OwnerWithdrawalsInitial());

  Future<void> fetchWithdrawals() async {
    emit(OwnerWithdrawalsLoading());
    final res = await ApiServiceUnified.instance.getOwnerWithdrawals();
    if (res['status'] == 'success') {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final balance =
          double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
      final rawRequests = (data['requests'] as List?) ?? [];
      final requests = rawRequests
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      emit(OwnerWithdrawalsLoaded(balance: balance, requests: requests));
    } else {
      emit(OwnerWithdrawalsError(
          res['message'] as String? ?? 'Failed to load withdrawals.'));
    }
  }

  Future<void> requestWithdrawal(double amount) async {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(OwnerWithdrawalsActionLoading(loaded));
    final res =
        await ApiServiceUnified.instance.requestOwnerWithdrawal(amount);
    if (res['status'] == 'success') {
      emit(OwnerWithdrawalsActionSuccess(
          res['message'] as String? ?? 'Withdrawal request submitted.'));
      await fetchWithdrawals();
    } else {
      emit(OwnerWithdrawalsActionError(
        message: res['message'] as String? ?? 'Failed to submit withdrawal.',
        data: loaded,
      ));
      emit(loaded);
    }
  }

  Future<void> cancelWithdrawal(int id) async {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(OwnerWithdrawalsActionLoading(loaded));
    final res = await ApiServiceUnified.instance.cancelOwnerWithdrawal(id);
    if (res['status'] == 'success') {
      emit(OwnerWithdrawalsActionSuccess(
          res['message'] as String? ?? 'Withdrawal request cancelled.'));
      await fetchWithdrawals();
    } else {
      emit(OwnerWithdrawalsActionError(
        message: res['message'] as String? ?? 'Failed to cancel withdrawal.',
        data: loaded,
      ));
      emit(loaded);
    }
  }

  OwnerWithdrawalsLoaded? get _loaded {
    final s = state;
    if (s is OwnerWithdrawalsLoaded) return s;
    if (s is OwnerWithdrawalsActionLoading) return s.data;
    if (s is OwnerWithdrawalsActionError) return s.data;
    return null;
  }
}
