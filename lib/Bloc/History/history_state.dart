import 'package:equatable/equatable.dart';
import '../../Model/delivery_model.dart';

abstract class HistoryState extends Equatable {
  @override List<Object?> get props => [];
}

class HistoryInitial  extends HistoryState {}
class HistoryLoading  extends HistoryState {}
class HistoryLoaded   extends HistoryState {
  final List<DeliveryHistoryItem> deliveries;
  final int page;
  HistoryLoaded(this.deliveries, this.page);
  @override List<Object?> get props => [deliveries, page];
}
class HistoryError    extends HistoryState {
  final String message;
  HistoryError(this.message);
  @override List<Object?> get props => [message];
}
