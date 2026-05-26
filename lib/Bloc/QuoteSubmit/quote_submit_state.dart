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
