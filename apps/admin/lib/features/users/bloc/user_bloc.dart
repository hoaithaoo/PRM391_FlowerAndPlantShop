import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/admin_api_client.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AdminApiClient apiClient;

  UserBloc({required this.apiClient}) : super(UserInitial()) {
    on<FetchUsersEvent>(_onFetchUsers);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<UpdateUserRoleEvent>(_onUpdateUserRole);
  }

  Future<void> _onFetchUsers(
    FetchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final users = await apiClient.getUsers(
        page: event.page,
        search: event.search,
        role: event.role,
        status: event.status,
      );
      emit(UserLoaded(
        users: users,
        search: event.search,
        roleFilter: event.role,
        statusFilter: event.status,
      ));
    } catch (e) {
      emit(UserError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateUserStatus(
    UpdateUserStatusEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await apiClient.updateUser(
        event.userId,
        status: event.newStatus,
      );
      emit(UserActionSuccess(
        event.newStatus.name == 'disabled'
            ? 'Đã khóa tài khoản thành công!'
            : 'Đã mở khóa tài khoản thành công!',
      ));
      add(const FetchUsersEvent());
    } catch (e) {
      emit(UserError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRoleEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await apiClient.updateUser(
        event.userId,
        role: event.newRole,
      );
      emit(UserActionSuccess('Đã cập nhật vai trò người dùng thành công!'));
      add(const FetchUsersEvent());
    } catch (e) {
      emit(UserError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
