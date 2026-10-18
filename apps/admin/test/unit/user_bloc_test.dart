import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/users/bloc/user_bloc.dart';
import 'package:plant_flower_admin/features/users/bloc/user_event.dart';
import 'package:plant_flower_admin/features/users/bloc/user_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('UserBloc Unit Tests (Spec 9.2 - 9.4)', () {
    late MockAdminApiClient mockApiClient;
    late UserBloc userBloc;

    const testUser = UserProfile(
      id: 'user-001',
      email: 'customer@flower.vn',
      fullName: 'Khách Hàng Thân Thiết',
      phone: '0912345678',
      role: UserRole.user,
      status: AccountStatus.active,
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      userBloc = UserBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      userBloc.close();
    });

    test('Trạng thái khởi tạo ban đầu phải là UserInitial', () {
      expect(userBloc.state, equals(UserInitial()));
    });

    blocTest<UserBloc, UserState>(
      'FetchUsersEvent tải danh sách người dùng thành công',
      build: () {
        when(
          () => mockApiClient.getUsers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            role: any(named: 'role'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => [testUser]);
        return userBloc;
      },
      act: (bloc) => bloc.add(const FetchUsersEvent()),
      expect: () => [
        UserLoading(),
        const UserLoaded(users: [testUser]),
      ],
      verify: (_) {
        verify(
          () => mockApiClient.getUsers(page: 1, search: null, role: null, status: null),
        ).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'UpdateUserStatusEvent khóa tài khoản người dùng thành công',
      build: () {
        when(
          () => mockApiClient.updateUser(
            'user-001',
            status: AccountStatus.disabled,
          ),
        ).thenAnswer((_) async => testUser.copyWith(status: AccountStatus.disabled));
        when(
          () => mockApiClient.getUsers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            role: any(named: 'role'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => [testUser.copyWith(status: AccountStatus.disabled)]);
        return userBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateUserStatusEvent(
          userId: 'user-001',
          newStatus: AccountStatus.disabled,
        ),
      ),
      expect: () => [
        const UserActionSuccess('Đã khóa tài khoản thành công!'),
        UserLoading(),
        isA<UserLoaded>().having(
          (s) => s.users.first.status,
          'trạng thái sau khi khóa',
          AccountStatus.disabled,
        ),
      ],
      verify: (_) {
        verify(
          () => mockApiClient.updateUser('user-001', status: AccountStatus.disabled),
        ).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'Tự khóa tài khoản Admin chính mình phát ra UserError (ADMIN_SELF_LOCK_FORBIDDEN)',
      build: () {
        when(
          () => mockApiClient.updateUser(
            'admin-001',
            status: AccountStatus.disabled,
          ),
        ).thenThrow(
          Exception(
            'Không thể tự khóa hoặc hạ quyền tài khoản của chính mình (ADMIN_SELF_LOCK_FORBIDDEN)',
          ),
        );
        return userBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateUserStatusEvent(
          userId: 'admin-001',
          newStatus: AccountStatus.disabled,
        ),
      ),
      expect: () => [
        const UserError(
          'Không thể tự khóa hoặc hạ quyền tài khoản của chính mình (ADMIN_SELF_LOCK_FORBIDDEN)',
        ),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UpdateUserRoleEvent thăng cấp ADMIN thành công',
      build: () {
        when(
          () => mockApiClient.updateUser(
            'user-001',
            role: UserRole.admin,
          ),
        ).thenAnswer((_) async => testUser.copyWith(role: UserRole.admin));
        when(
          () => mockApiClient.getUsers(
            page: any(named: 'page'),
            search: any(named: 'search'),
            role: any(named: 'role'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => [testUser.copyWith(role: UserRole.admin)]);
        return userBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateUserRoleEvent(
          userId: 'user-001',
          newRole: UserRole.admin,
        ),
      ),
      expect: () => [
        const UserActionSuccess('Đã cập nhật vai trò người dùng thành công!'),
        UserLoading(),
        isA<UserLoaded>().having(
          (s) => s.users.first.role,
          'vai trò sau khi cập nhật',
          UserRole.admin,
        ),
      ],
    );
  });
}
