abstract class OwnerWalletState {}

class OwnerWalletInitial extends OwnerWalletState {}

class OwnerWalletLoading extends OwnerWalletState {}

class OwnerWalletLoaded extends OwnerWalletState {
  final double balance;
  final List<Map<String, dynamic>> transactions;
  final Map<String, dynamic>? pendingWithdrawal;

  OwnerWalletLoaded({
    required this.balance,
    required this.transactions,
    this.pendingWithdrawal,
  });
}

class OwnerWalletError extends OwnerWalletState {
  final String message;
  OwnerWalletError(this.message);
}

/// Emitted while an action (withdraw, cancel) is in flight.
/// Carries current data so the UI keeps rendering behind the overlay.
class OwnerWalletActionLoading extends OwnerWalletState {
  final OwnerWalletLoaded data;
  OwnerWalletActionLoading(this.data);
}

class OwnerWalletActionSuccess extends OwnerWalletState {
  final String message;
  OwnerWalletActionSuccess(this.message);
}

class OwnerWalletActionError extends OwnerWalletState {
  final String message;
  final OwnerWalletLoaded data;
  OwnerWalletActionError({required this.message, required this.data});
}
