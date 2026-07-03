abstract class QuoteSubmitState {}

class QuoteSubmitInitial extends QuoteSubmitState {}

class QuoteSubmitLoading extends QuoteSubmitState {}

class QuoteSubmitSuccess extends QuoteSubmitState {
  final String message;
  QuoteSubmitSuccess(this.message);
}

class QuoteSubmitError extends QuoteSubmitState {
  final String message;
  QuoteSubmitError(this.message);
}

/// The quote could not be submitted because the owner's wallet cannot cover the
/// required compensation deposit. Drives the "Add money to wallet" prompt.
class QuoteSubmitInsufficientFunds extends QuoteSubmitState {
  final String message;
  QuoteSubmitInsufficientFunds(this.message);
}
