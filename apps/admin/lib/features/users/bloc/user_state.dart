import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserProfile> users;
  final String? search;
  final UserRole? roleFilter;
  final AccountStatus? statusFilter;

  const UserLoaded({
    required this.users,
    this.search,
    this.roleFilter,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [users, search, roleFilter, statusFilter];
}

class UserActionSuccess extends UserState {
  final String message;

  const UserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}
