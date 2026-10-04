# Đăng nhập bằng Supabase Auth

Hệ thống hỗ trợ ba cách đăng nhập:

1. Google OAuth 2.0.
2. Email OTP gồm 6 chữ số.
3. Email và password.

Supabase Auth quản lý `auth.users`, identity, password hash, OTP và session.
Backend không có endpoint `/login`, không lưu password/OTP và không dùng
`profiles` làm bảng xác thực. Sau khi đăng nhập, app gửi Supabase `access_token`
đến Render API qua `Authorization: Bearer <token>`.

## 1. Biến môi trường phía Flutter

App chỉ được nhận Project URL và publishable key:

```text
SUPABASE_URL=https://PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Publishable key được thiết kế để nằm trong app client. Không đưa database URL,
database password, secret key hay `service_role` key vào Flutter, Next.js client
hoặc Git.

Khởi tạo SDK:

```dart
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabasePublishableKey,
);
```

## 2. Google OAuth 2.0

Trong Google Cloud Console, tạo OAuth client loại **Web application**. Thêm
callback URL được hiển thị trong **Supabase Dashboard > Authentication >
Providers > Google** vào **Authorized redirect URIs**, rồi nhập Client ID và
Client Secret vào provider Google của Supabase. Client Secret chỉ đặt trong
Dashboard, không commit vào repository.

Với Flutter mobile, khai báo custom URL scheme, sau đó thêm URL đó vào
**Authentication > URL Configuration > Redirect URLs**. Ví dụ:

```dart
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'com.plantflowershop.mobile://login-callback/',
  authScreenLaunchMode: LaunchMode.externalApplication,
);
```

Web có thể bỏ `redirectTo` nếu Site URL đã đúng. Xem hướng dẫn chính thức:
[Google login](https://supabase.com/docs/guides/auth/social-login/auth-google),
[Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
và [redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls).

## 3. Email OTP 6 chữ số

Bật Email provider. Trong **Authentication > Email Templates**, sửa template
Magic Link để nội dung dùng `{{ .Token }}` thay vì chỉ dùng
`{{ .ConfirmationURL }}`. Sau đó gửi OTP:

```dart
await Supabase.instance.client.auth.signInWithOtp(
  email: email.trim(),
  shouldCreateUser: true,
);
```

Xác minh mã user nhập:

```dart
final response = await Supabase.instance.client.auth.verifyOTP(
  email: email.trim(),
  token: otp.trim(),
  type: OtpType.email,
);

final session = response.session;
```

Không log OTP và không gửi OTP đến backend Render. Xem
[email templates](https://supabase.com/docs/guides/auth/auth-email-templates),
[signInWithOtp](https://supabase.com/docs/reference/dart/auth-signinwithotp) và
[verifyOTP](https://supabase.com/docs/reference/dart/auth-verifyotp).

## 4. Email và password

Đăng ký tài khoản:

```dart
final response = await Supabase.instance.client.auth.signUp(
  email: email.trim(),
  password: password,
  data: {'full_name': fullName.trim()},
);
```

Nếu **Confirm email** đang bật, user phải xác nhận email trước khi có session
đăng nhập hoàn chỉnh. Đăng nhập tài khoản đã đăng ký:

```dart
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email.trim(),
  password: password,
);

final session = response.session;
```

App không tự lưu password. Dùng luồng reset password của Supabase khi user quên
mật khẩu. Xem [password auth](https://supabase.com/docs/guides/auth/passwords)
và [Flutter signInWithPassword](https://supabase.com/docs/reference/dart/auth-signinwithpassword).

## 5. Gọi backend sau đăng nhập

Ba phương thức đăng nhập đều trả cùng kiểu Supabase session. Lấy access token và
gắn vào protected request:

```dart
final token = Supabase.instance.client.auth.currentSession?.accessToken;

final response = await http.get(
  Uri.parse('$apiBaseUrl/api/v1/profile'),
  headers: {'Authorization': 'Bearer $token'},
);
```

Backend xác minh token với Supabase, rồi tạo `profiles` ở protected request đầu
tiên. Với Google, backend lấy `full_name`/`name` và `avatar_url`/`picture` từ
verified user metadata để khởi tạo profile. Email/password và OTP dùng cùng cơ
chế, vì vậy không cần thêm cột password, OTP hay auth provider vào Prisma.

## 6. Checklist

- Google callback URI và mobile redirect URL khớp chính xác.
- Site URL dùng đúng domain production.
- Confirm email được bật/tắt theo yêu cầu sản phẩm.
- Template OTP dùng `{{ .Token }}`.
- Cấu hình SMTP riêng trước khi production gửi email thật.
- App xử lý session hết hạn và yêu cầu đăng nhập lại khi backend trả 401.
- Không commit OAuth Client Secret, database credentials hoặc Supabase secret.
