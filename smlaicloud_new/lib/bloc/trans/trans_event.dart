part of 'trans_bloc.dart';

abstract class TransEvent extends Equatable {
  const TransEvent();

  @override
  List<Object> get props => [];
}

class TransGet extends TransEvent {
  final String guid;

  const TransGet({required this.guid});

  @override
  List<Object> get props => [guid];
}

class TransLoad extends TransEvent {
  final String custcode;
  final int limit;
  final int offset;
  final String search;
  final TransactionTypeEnum type;
  final String? ispos;
  const TransLoad({
    required this.offset,
    required this.limit,
    required this.search,
    required this.type,
    required this.custcode,
    this.ispos,
  });

  @override
  List<Object> get props => [];
}

class TransDelete extends TransEvent {
  final String guid;
  final TransactionTypeEnum type;
  const TransDelete({
    required this.guid,
    required this.type,
  });

  @override
  List<Object> get props => [guid, type];
}

class TransDeleteMany extends TransEvent {
  final List<String> guid;

  const TransDeleteMany({
    required this.guid,
  });

  @override
  List<Object> get props => [guid];
}

class TransSave extends TransEvent {
  final TransactionModel trans;
  final TransactionTypeEnum type;
  const TransSave({
    required this.trans,
    required this.type,
  });

  @override
  List<Object> get props => [trans, type];
}

class TransUpdate extends TransEvent {
  final String guid;
  final TransactionModel trans;
  final TransactionTypeEnum type;
  const TransUpdate({
    required this.guid,
    required this.trans,
    required this.type,
  });

  @override
  List<Object> get props => [guid, trans, type];
}

class TransCreateFullInvoice extends TransEvent {
  final String guid;
  final TransactionModel trans;
  final TransactionTypeEnum type;
  
  const TransCreateFullInvoice({
    required this.guid,
    required this.trans,
    required this.type,
  });

  @override
  List<Object> get props => [guid, trans, type];
}
