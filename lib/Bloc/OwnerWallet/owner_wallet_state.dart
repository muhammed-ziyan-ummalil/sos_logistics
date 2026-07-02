abstract class OwnerWalletState {}

class OwnerWalletInitial extends OwnerWalletState {}

class OwnerWalletLoading extends OwnerWalletState {}

class OwnerWalletLoaded extends OwnerWalletState {
  final double balance;
  final List<Map<String, dynamic>> transactions;

  OwnerWalletLoaded({
    required this.balance,
    required this.transactions,
  });
}

class OwnerWalletError extends OwnerWalletState {
  final String message;
  OwnerWalletError(this.message);
}
