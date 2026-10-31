import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile profile;

  const AuthAuthenticated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
