part of 'point_transaction_bloc.dart';

abstract class PointTransactionState extends Equatable {
  const PointTransactionState();

  @override
  List<Object> get props => [];
}

class PointTransactionInitial extends PointTransactionState {}

class PointTransactionInProgress extends PointTransactionState {}

class PointTransactionLoadSuccess extends PointTransactionState {
  final List<PointTransactionModel> transactions;

  const PointTransactionLoadSuccess({required this.transactions});

  PointTransactionLoadSuccess copyWith({
    List<PointTransactionModel>? transactions,
  }) =>
      PointTransactionLoadSuccess(transactions: transactions ?? this.transactions);

  @override
  List<Object> get props => [transactions];
}

class PointTransactionLoadFailed extends PointTransactionState {
  final String message;

  const PointTransactionLoadFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
