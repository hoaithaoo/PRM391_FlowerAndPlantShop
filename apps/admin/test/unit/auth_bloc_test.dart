import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/auth/bloc/auth_bloc.dart';
import 'package:plant_flower_admin/features/auth/bloc/auth_event.dart';
import 'package:plant_flower_admin/features/auth/bloc/auth_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('AuthBloc Unit Tests (Role Guard & Auth Validation)', () {
    late MockAdminApiClient mockApiClient;
    late AuthBloc authBloc;

    const adminProfile = UserProfile(
      id: 'admin_1',
      email: 'admin@nhacohoa.vn',
      fullName: 'Nguyễn Tiến Admin',
      role: UserRole.admin,
      status: AccountStatus.active,
    );

    const regularUserProfile = UserProfile(
      id: 'user_1',
      email: 'khachhang@gmail.com',
      fullName: 'Khách Hàng',
      role: UserRole.user, // Not ADMIN
      status: AccountStatus.active,
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      authBloc = AuthBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      authBloc.close();
    });

    test('Trạng thái khởi tạo là AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'Đăng nhập thành công với quyền ADMIN -> phát ra [AuthLoading, AuthAuthenticated]',
      build: () {
        when(() => mockApiClient.loginWithEmailPassword('admin@nhacohoa.vn', 'Admin@123'))
            .thenAnswer((_) async => adminProfile);
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginSubmittedEvent(
        email: 'admin@nhacohoa.vn',
        password: 'Admin@123',
      )),
      expect: () => [
        AuthLoading(),
        const AuthAuthenticated(adminProfile),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Chặn đăng nhập khi tài khoản chỉ có quyền USER -> phát ra [AuthLoading, AuthError]',
      build: () {
        when(() => mockApiClient.loginWithEmailPassword('khachhang@gmail.com', '123456'))
            .thenAnswer((_) async => regularUserProfile);
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginSubmittedEvent(
        email: 'khachhang@gmail.com',
        password: '123456',
      )),
      expect: () => [
        AuthLoading(),
        const AuthError('Tài khoản của bạn không có quyền Quản trị viên (ADMIN)!'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Đăng xuất -> phát ra [AuthUnauthenticated]',
      build: () {
        when(() => mockApiClient.setAuthToken(null)).thenReturn(null);
        return authBloc;
      },
      act: (bloc) => bloc.add(LogoutRequestedEvent()),
      expect: () => [
        AuthUnauthenticated(),
      ],
    );
  });
}
