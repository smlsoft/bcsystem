part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UserGet extends UserEvent {
  final String username;

  const UserGet({required this.username});

  @override
  List<Object> get props => [username];
}

class UserLoadList extends UserEvent {
  final int limit;
  final int offset;
  final String search;

  const UserLoadList({required this.offset, required this.limit, required this.search});

  @override
  List<Object> get props => [];
}

class UserDelete extends UserEvent {
  final String username;

  const UserDelete({
    required this.username,
  });

  @override
  List<Object> get props => [username];
}

class UserSaveAndUpdate extends UserEvent {
  final UserModel userModel;

  const UserSaveAndUpdate({
    required this.userModel,
  });

  @override
  List<Object> get props => [userModel];
}
