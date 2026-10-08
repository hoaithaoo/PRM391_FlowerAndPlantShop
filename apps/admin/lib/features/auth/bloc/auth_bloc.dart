import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/admin_api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AdminApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(AuthInitial()) {
    apiClient.onSessionExpired = () {
      add(const SessionExpiredEvent());
    };

    on<CheckAuthSessionEvent>(_onCheckSession);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<SessionExpiredEvent>(_onSessionExpired);
  }

  Future<void> _onCheckSession(CheckAuthSessionEvent event, Emitter<AuthState> emit) async {
    if (apiClient.authToken != null) {
      // Session exists
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmittedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final profile = await apiClient.loginWithEmailPassword(event.email, event.password);
      if (!profile.isAdmin) {
        emit(const AuthError('Tài khoản của bạn không có quyền Quản trị viên (ADMIN)!'));
        return;
      }
      if (!profile.isActive) {
        emit(const AuthError('Tài khoản Quản trị viên đang bị vô hiệu hóa (ACCOUNT_DISABLED)!'));
        return;
      }
      emit(AuthAuthenticated(profile));
    } catch (e) {
      if (e is ForbiddenException) {
        emit(const AuthError('Tài khoản của bạn không có quyền Quản trị viên (ADMIN)!'));
      } else if (e is AccountDisabledException) {
        emit(const AuthError('Tài khoản Quản trị viên đang bị vô hiệu hóa (ACCOUNT_DISABLED)!'));
      } else {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  Future<void> _onLogoutRequested(LogoutRequestedEvent event, Emitter<AuthState> emit) async {
    apiClient.setAuthToken(null);
    emit(AuthUnauthenticated());
  }

  Future<void> _onSessionExpired(SessionExpiredEvent event, Emitter<AuthState> emit) async {
    apiClient.setAuthToken(null);
    emit(const AuthError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'));
    emit(AuthUnauthenticated());
  }
}
