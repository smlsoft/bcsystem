part of 'list_kiosk_bloc.dart';

abstract class ListKioskState extends Equatable {
  const ListKioskState();

  @override
  List<Object> get props => [];
}

class ListKioskInitial extends ListKioskState {}

class ListKioskInProgress extends ListKioskState {}

// ignore: must_be_immutable
class ListKioskLoadSuccess extends ListKioskState {
  List<KioskListModel> kiosk;

  ListKioskLoadSuccess({
    required this.kiosk,
  });

  @override
  List<Object> get props => [kiosk];
}

class ListKioskLoadFailed extends ListKioskState {
  final String message;
  const ListKioskLoadFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
