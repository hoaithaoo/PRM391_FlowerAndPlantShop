import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

/// Màn hình cỡ nhỏ và cỡ phổ biến dùng cho test overflow.
const kSmallPhone = Size(360, 640);
const kPhone = Size(390, 844);

/// true khi chạy với `PFS_TEST_FONT=ahem` (font Ahem rộng 1em mỗi ký tự).
/// Test chỉ hợp lệ với font thật dùng `skip: kAhemFont`.
final bool kAhemFont =
    Platform.environment['PFS_TEST_FONT']?.toLowerCase() == 'ahem';

const kHomeText = 'HOME_STUB';
const kLoginSuccessText = 'Đăng nhập thành công. Chào mừng bạn đến Fleuré!';

/// Repository giả bọc [MockAuthRepository]: đếm số lần gọi, ghi lại tham số,
/// cho phép giữ request lại bằng [Completer] hoặc ép ném lỗi.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Duration delay = Duration.zero})
    : _inner = MockAuthRepository(delay: delay) {
    _innerSub = _inner.signedInChanges.listen(_signedIn.add);
  }

  final MockAuthRepository _inner;
  late final StreamSubscription<bool> _innerSub;
  final _signedIn = StreamController<bool>.broadcast();

  /// Nhật ký tên phương thức đã gọi theo thứ tự.
  final calls = <String>[];
  final _blockers = <String, Completer<void>>{};
  final _failures = <String, Object>{};

  String? lastEmail;
  String? lastPassword;
  RegisterRequest? lastSignUp;

  /// Ép kết quả signUp (mặc định theo Mock: needsEmailVerification).
  SignUpResult? forcedSignUpResult;

  int count(String method) => calls.where((c) => c == method).length;

  /// Giữ request của [method] lại cho tới khi gọi `complete()`.
  Completer<void> block(String method) {
    return _blockers[method] = Completer<void>();
  }

  /// Khiến [method] ném [error] (sau khi hết block nếu có).
  void failWith(String method, Object error) => _failures[method] = error;

  /// Gỡ lỗi đã ép bằng [failWith].
  void clearFailure(String method) => _failures.remove(method);

  void emitSignedIn(bool value) => _signedIn.add(value);

  /// Giả lập người dùng bấm link xác nhận trong email (phát signedIn = true).
  void simulateEmailConfirmed() => _inner.simulateEmailConfirmed();

  Future<void> _enter(String method) async {
    calls.add(method);
    final blocker = _blockers[method];
    if (blocker != null) await blocker.future;
    final failure = _failures[method];
    if (failure != null) throw failure;
  }

  Future<void> dispose() async {
    await _innerSub.cancel();
    await _signedIn.close();
    await _inner.dispose();
  }

  @override
  bool get isSignedIn => _inner.isSignedIn;

  @override
  Stream<bool> get signedInChanges => _signedIn.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    await _enter('signInWithPassword');
    return _inner.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _enter('signInWithGoogle');
    return _inner.signInWithGoogle();
  }

  @override
  Future<void> resendSignupEmail({required String email}) async {
    lastEmail = email;
    await _enter('resendSignupEmail');
    return _inner.resendSignupEmail(email: email);
  }

  @override
  Future<SignUpResult> signUp(RegisterRequest request) async {
    lastSignUp = request;
    await _enter('signUp');
    final forced = forcedSignUpResult;
    if (forced != null) return forced;
    return _inner.signUp(request);
  }

  @override
  Future<void> signOut() async {
    await _enter('signOut');
    return _inner.signOut();
  }
}

/// Dựng app auth bọc [AuthScope]. Mặc định có màn nền [kHomeText] ở đáy stack
/// để kiểm tra pop/completeAuth; truyền [home] để thay (vd. màn là route đầu).
Future<GlobalKey<NavigatorState>> pumpAuthApp(
  WidgetTester tester,
  AuthRepository repository, {
  Size size = kSmallPhone,
  Widget? home,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    AuthScope(
      repository: repository,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AuthTheme.data(ThemeData(useMaterial3: true)),
        onGenerateRoute: AuthRoutes.onGenerateRoute,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home ?? const Scaffold(body: Center(child: Text(kHomeText))),
      ),
    ),
  );
  await tester.pump();
  return navigatorKey;
}

/// Đẩy route auth lên trên màn nền và chờ animation chuyển trang xong.
Future<void> pushRoute(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigatorKey,
  String name, {
  Object? arguments,
}) async {
  unawaited(navigatorKey.currentState!.pushNamed(name, arguments: arguments));
  await tester.pumpAndSettle();
}

Finder byKey(String key) => find.byKey(Key(key));

/// Cuộn tới widget rồi chạm (màn 360x640 nhiều phần tử nằm ngoài khung nhìn).
Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// Nhập text vào AuthTextField theo key.
Future<void> enterIn(WidgetTester tester, String key, String text) async {
  final finder = byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.enterText(finder, text);
  await tester.pump();
}

/// Nội dung TextField nằm trong AuthTextField có key [key].
String textOf(WidgetTester tester, String key) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: byKey(key), matching: find.byType(EditableText)),
  );
  return editable.controller.text;
}

/// Cho các Future/microtask của repository (delay 0) chạy xong.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // Chờ animation đóng route/SnackBar xong (không dùng khi còn spinner)
  await tester.pumpAndSettle();
}

/// Gỡ cây widget để huỷ Timer/controller trước khi test kết thúc.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

/// Lấy SnackBar đang hiện (nếu có) dưới dạng text.
Finder snackText(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

/// `testWidgets` kèm một [FakeAuthRepository] mới.
///
/// Repo phải được tạo bên trong FakeAsync zone của test (không tạo ở `setUp`),
/// nếu không các sự kiện stream của nó không được bơm bởi `tester.pump`.
void authTestWidgets(
  String description,
  Future<void> Function(WidgetTester tester, FakeAuthRepository repo) body, {
  Object? skip,
}) {
  testWidgets(description, (tester) async {
    final repo = FakeAuthRepository();
    await body(tester, repo);
    unawaited(repo.dispose());
  }, skip: skip == null || skip == false ? null : true);
}

/// Bàn phím ảo che [height] px đáy màn hình.
void showKeyboard(WidgetTester tester, double height) {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  addTearDown(tester.view.resetViewInsets);
}

/// Chờ [future] hoàn tất trong FakeAsync bằng cách bơm đồng hồ từng 1ms
/// (repository giả dùng `Future.delayed`, không tự chạy nếu không pump).
Future<T> resolve<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  T? value;
  Object? error;
  StackTrace? stack;
  future.then(
    (v) {
      value = v;
      done = true;
    },
    onError: (Object e, StackTrace s) {
      error = e;
      stack = s;
      done = true;
    },
  );
  for (var i = 0; i < 50 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  if (!done) fail('Future chưa hoàn tất sau 50ms giả lập');
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  return value as T;
}
