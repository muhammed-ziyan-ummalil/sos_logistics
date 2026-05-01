import 'package:equatable/equatable.dart';
import '../../Model/earnings_model.dart';

abstract class EarningsState extends Equatable {
  @override List<Object?> get props => [];
}

class EarningsInitial extends EarningsState {}
class EarningsLoading extends EarningsState {}
class EarningsLoaded  extends EarningsState {
  final EarningsData data;
  EarningsLoaded(this.data);
  @override List<Object?> get props => [data];
}
class EarningsError   extends EarningsState {
  final String message;
  EarningsError(this.message);
  @override List<Object?> get props => [message];
}
