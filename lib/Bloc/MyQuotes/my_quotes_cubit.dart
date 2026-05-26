import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utility/api_service.dart';
import '../../Model/delivery_quote_model.dart';
import 'my_quotes_state.dart';

class MyQuotesCubit extends Cubit<MyQuotesState> {
  MyQuotesCubit() : super(MyQuotesInitial());

  Future<void> fetchMyQuotes() async {
    emit(MyQuotesLoading());
    final res = await ApiServiceUnified.instance.get('owner/my-quotes');
    if (res['status'] == 'success') {
      final list = (res['data'] as List? ?? [])
          .map((j) => DeliveryQuoteModel.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(MyQuotesLoaded(list));
    } else {
      emit(MyQuotesError(res['message'] as String? ?? 'Failed to load quotes.'));
    }
  }
}
