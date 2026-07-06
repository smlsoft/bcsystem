import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PayScreenEvent {}

abstract class PayScreenState {}

class PayScreenBloc extends Bloc<PayScreenEvent, PayScreenState> {
  PayScreenBloc() : super(PayScreenInitial()) {
    on<PayScreenRefresh>(_refresh);
  }

  void _refresh(PayScreenRefresh event, Emitter<PayScreenState> emit) async {
    emit(PayScreenRefreshFinish());
  }
}

class PayScreenRefresh extends PayScreenEvent {}

class PayScreenSuccess extends PayScreenEvent {}

class PayScreenRefreshFinish extends PayScreenState {}

class PayScreenInitial extends PayScreenState {}
