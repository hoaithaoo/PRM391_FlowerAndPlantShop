import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  AuthFailure map(String? code) => SupabaseAuthRepository.mapAuthException(
    AuthException('raw server message', code: code),
  );

  void expectMapped(String code, AuthFailureCode expected, String message) {
    final failure = map(code);
    expect(failure.code, expected, reason: 'code của "$code"');
    expect(failure.message, message, reason: 'message của "$code"');
  }

  test('invalid_credentials', () {
    expectMapped(
      'invalid_credentials',
      AuthFailureCode.invalidCredentials,
      'Email hoặc mật khẩu không đúng.',
    );
  });

  test('email_not_confirmed', () {
    expectMapped(
      'email_not_confirmed',
      AuthFailureCode.emailNotConfirmed,
      'Email chưa được xác thực. Vui lòng kiểm tra hộp thư của bạn.',
    );
  });

  test('user_already_exists và email_exists cùng một kết quả', () {
    for (final code in ['user_already_exists', 'email_exists']) {
      expectMapped(
        code,
        AuthFailureCode.userAlreadyExists,
        'Email này đã được đăng ký. Vui lòng đăng nhập.',
      );
    }
  });

  test('otp_expired và otp_disabled không còn map riêng -> unknown', () {
    for (final code in ['otp_expired', 'otp_disabled']) {
      expectMapped(code, AuthFailureCode.unknown, AuthFailure.unknown.message);
    }
  });

  test('user_not_found', () {
    expectMapped(
      'user_not_found',
      AuthFailureCode.invalidCredentials,
      'Không tìm thấy tài khoản với email này.',
    );
  });

  test('over_email_send_rate_limit và over_request_rate_limit', () {
    for (final code in [
      'over_email_send_rate_limit',
      'over_request_rate_limit',
    ]) {
      expectMapped(
        code,
        AuthFailureCode.rateLimited,
        'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.',
      );
    }
  });

  test('weak_password', () {
    expectMapped(
      'weak_password',
      AuthFailureCode.weakPassword,
      'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.',
    );
  });

  test('code lạ -> unknown', () {
    final failure = map('some_new_server_code');
    expect(failure.code, AuthFailureCode.unknown);
    expect(failure.message, AuthFailure.unknown.message);
  });

  test('code null -> unknown', () {
    final failure = map(null);
    expect(failure.code, AuthFailureCode.unknown);
    expect(failure.message, AuthFailure.unknown.message);
  });

  test('code phân biệt hoa/thường: "INVALID_CREDENTIALS" coi là lạ', () {
    expect(map('INVALID_CREDENTIALS').code, AuthFailureCode.unknown);
  });

  test('không rò rỉ message thô của server ra cho người dùng', () {
    for (final code in [
      'invalid_credentials',
      'weak_password',
      'some_new_server_code',
      null,
    ]) {
      expect(map(code).message, isNot(contains('raw server message')));
    }
  });
}
