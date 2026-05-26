import '../../Model/delivery_quote_model.dart';

abstract class MyQuotesState {}

class MyQuotesInitial extends MyQuotesState {}

class MyQuotesLoading extends MyQuotesState {}

class MyQuotesLoaded extends MyQuotesState {
  final List<DeliveryQuoteModel> quotes;
  MyQuotesLoaded(this.quotes);
}

class MyQuotesError extends MyQuotesState {
  final String message;
  MyQuotesError(this.message);
}
