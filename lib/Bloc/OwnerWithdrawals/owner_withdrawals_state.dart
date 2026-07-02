abstract class OwnerWithdrawalsState {}

class OwnerWithdrawalsInitial extends OwnerWithdrawalsState {}

class OwnerWithdrawalsLoading extends OwnerWithdrawalsState {}

class OwnerWithdrawalsLoaded extends OwnerWithdrawalsState {
  final double balance;
  final List<Map<String, dynamic>> requests;

  OwnerWithdrawalsLoaded({
    required this.balance,
    required this.requests,
  });
}

class OwnerWithdrawalsError extends OwnerWithdrawalsState {
  final String message;
  OwnerWithdrawalsError(this.message);
}

/// Emitted while an action (request, cancel) is in flight.
/// Carries current data so the UI keeps rendering behind the overlay.
class OwnerWithdrawalsActionLoading extends OwnerWithdrawalsState {
  final OwnerWithdrawalsLoaded data;
  OwnerWithdrawalsActionLoading(this.data);
}

class OwnerWithdrawalsActionSuccess extends OwnerWithdrawalsState {
  final String message;
  OwnerWithdrawalsActionSuccess(this.message);
}

class OwnerWithdrawalsActionError extends OwnerWithdrawalsState {
  final String message;
  final OwnerWithdrawalsLoaded data;
  OwnerWithdrawalsActionError({required this.message, required this.data});
}
