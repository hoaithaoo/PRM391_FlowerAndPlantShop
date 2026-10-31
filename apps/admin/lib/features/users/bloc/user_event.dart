import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsersEvent extends UserEvent {
  final int page;
  final String? search;
  final UserRole? role;
  final AccountStatus? status;

  const FetchUsersEvent({
    this.page = 1,
    this.search,
    this.role,
    this.status,
  });

  @override
  List<Object?> get props => [page, search, role, status];
}

class UpdateUserStatusEvent extends UserEvent {
  final String userId;
  final AccountStatus newStatus;

  const UpdateUserStatusEvent({
    required this.userId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [userId, newStatus];
}

class UpdateUserRoleEvent extends UserEvent {
  final String userId;
  final UserRole newRole;

  const UpdateUserRoleEvent({
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [userId, newRole];
}
