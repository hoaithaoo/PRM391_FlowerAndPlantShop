import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/utils/auth_validators.dart';

void main() {
  group('fullName', () {
    test('rỗng hoặc chỉ có khoảng trắng', () {
      expect(AuthValidators.fullName(''), 'Vui lòng nhập họ và tên.');
      expect(AuthValidators.fullName('   '), 'Vui lòng nhập họ và tên.');
    });

    test('chứa số và ký tự đặc biệt (dữ liệu màn Đăng ký - Lỗi)', () {
      expect(
        AuthValidators.fullName('Phương Hà 123@#'),
        'Tên không được chứa số và các ký tự đặc biệt.',
      );
      expect(AuthValidators.fullName('Ha_Nguyen'), isNotNull);
      expect(AuthValidators.fullName('Hà-Nguyễn'), isNotNull);
    });

    test('tên tiếng Việt có dấu hợp lệ', () {
      expect(AuthValidators.fullName('Nguyễn Phương Hà'), isNull);
      expect(AuthValidators.fullName('Đặng Thị Ngọc Ánh'), isNull);
      expect(AuthValidators.fullName('  Trần Văn Ưu  '), isNull);
      expect(AuthValidators.fullName('Nguyen Van A'), isNull);
    });

    test('biên 100 ký tự', () {
      expect(AuthValidators.fullName('a' * 100), isNull);
      expect(AuthValidators.fullName('a' * 101), 'Họ và tên tối đa 100 ký tự.');
    });

    test('khoảng trắng hai đầu không tính vào độ dài', () {
      expect(AuthValidators.fullName('  ${'a' * 100}  '), isNull);
    });
  });

  group('phone', () {
    const invalidMessage =
        'Số điện thoại chỉ được chứa chữ số hoặc định dạng (+mã quốc gia) '
        'số (ví dụ: +84912345678 hoặc 0912345678), không được chứa chữ cái '
        'hay ký tự đặc biệt.';

    test('rỗng', () {
      expect(AuthValidators.phone(''), 'Vui lòng nhập số điện thoại.');
      expect(AuthValidators.phone('  '), 'Vui lòng nhập số điện thoại.');
    });

    test('"0912-abc-xyz" (màn Đăng ký - Lỗi) báo đúng nguyên văn', () {
      expect(AuthValidators.phone('0912-abc-xyz'), invalidMessage);
    });

    test('hợp lệ: 0xxxxxxxxx và +84xxxxxxxxx', () {
      expect(AuthValidators.phone('0912345678'), isNull);
      expect(AuthValidators.phone('+84912345678'), isNull);
    });

    test('trim khoảng trắng hai đầu', () {
      expect(AuthValidators.phone('  0912345678  '), isNull);
    });

    test('thiếu hoặc thừa chữ số', () {
      expect(AuthValidators.phone('091234567'), invalidMessage); // 9 số
      expect(AuthValidators.phone('09123456789'), invalidMessage); // 11 số
      expect(AuthValidators.phone('+8491234567'), invalidMessage);
      expect(AuthValidators.phone('+849123456789'), invalidMessage);
    });

    test('khoảng trắng giữa các nhóm số như placeholder là hợp lệ', () {
      expect(AuthValidators.phone('0912 345 678'), isNull);
      expect(AuthValidators.phone('+84 912 345 678'), isNull);
    });

    test('sai tiền tố / ký tự lạ', () {
      expect(AuthValidators.phone('9123456789'), invalidMessage);
      expect(AuthValidators.phone('+1912345678'), invalidMessage);
      expect(AuthValidators.phone('0912.345.678'), invalidMessage);
      expect(AuthValidators.phone('84912345678'), invalidMessage);
    });
  });

  group('email', () {
    const invalidMessage =
        'Email không đúng định dạng tiêu chuẩn (ví dụ hợp lệ: '
        'name@example.com).';

    test('rỗng', () {
      expect(AuthValidators.email(''), 'Vui lòng nhập địa chỉ email.');
      expect(AuthValidators.email('   '), 'Vui lòng nhập địa chỉ email.');
    });

    test(
      '"phuongha.fleuré@domain" (màn Đăng ký - Lỗi) báo đúng nguyên văn',
      () {
        expect(AuthValidators.email('phuongha.fleuré@domain'), invalidMessage);
      },
    );

    test('hợp lệ', () {
      expect(AuthValidators.email('name@example.com'), isNull);
      expect(AuthValidators.email('phuong.ha+shop@mail.fleure.vn'), isNull);
    });

    test('thiếu TLD, thiếu @, thiếu tên miền', () {
      expect(AuthValidators.email('name@domain'), invalidMessage);
      expect(AuthValidators.email('name@domain.'), invalidMessage);
      expect(AuthValidators.email('name@.com'), invalidMessage);
      expect(AuthValidators.email('name.example.com'), invalidMessage);
      expect(AuthValidators.email('@example.com'), invalidMessage);
      expect(AuthValidators.email('name@'), invalidMessage);
      expect(AuthValidators.email('name@example.c'), invalidMessage);
    });

    test('không phân biệt hoa/thường', () {
      expect(AuthValidators.email('NAME@EXAMPLE.COM'), isNull);
      expect(AuthValidators.email('Name@Example.Com'), isNull);
    });

    test('trim khoảng trắng hai đầu, từ chối khoảng trắng bên trong', () {
      expect(AuthValidators.email('  name@example.com  '), isNull);
      expect(AuthValidators.email('na me@example.com'), invalidMessage);
      expect(AuthValidators.email('name@exa mple.com'), invalidMessage);
    });

    test('isEmail / isPhone là hàm bool tương ứng', () {
      expect(AuthValidators.isEmail(' a@b.vn '), isTrue);
      expect(AuthValidators.isEmail('a@b'), isFalse);
      expect(AuthValidators.isPhone(' 0912345678 '), isTrue);
      expect(AuthValidators.isPhone('0912'), isFalse);
    });
  });

  group('address', () {
    test('rỗng', () {
      expect(AuthValidators.address(''), 'Vui lòng nhập địa chỉ nhận hàng.');
      expect(
        AuthValidators.address('    '),
        'Vui lòng nhập địa chỉ nhận hàng.',
      );
    });

    test('quá ngắn (< 5 ký tự sau trim)', () {
      const tooShort = 'Địa chỉ quá ngắn, vui lòng nhập chi tiết hơn.';
      expect(AuthValidators.address('abcd'), tooShort);
      expect(AuthValidators.address('  abcd  '), tooShort);
      expect(AuthValidators.address('abcde'), isNull); // biên 5 ký tự
    });

    test('địa chỉ hợp lệ như thiết kế', () {
      expect(
        AuthValidators.address(
          '470 An Dương Vương, P. An Lạc, Bình Tân, TP.HCM',
        ),
        isNull,
      );
    });
  });

  group('password & PasswordRules', () {
    const weakMessage =
        'Mật khẩu phải tối thiểu 8 ký tự, có ít nhất 1 chữ cái in hoa, 1 '
        'chữ số và 1 ký tự đặc biệt (@, #, \$, %, v.v.).';

    test('rỗng', () {
      expect(AuthValidators.password(''), 'Vui lòng nhập mật khẩu.');
    });

    test('"hoa12345": đạt 8 ký tự + chữ số, thiếu in hoa + ký tự đặc biệt', () {
      final rules = PasswordRules.of('hoa12345');
      expect(rules.hasMinLength, isTrue);
      expect(rules.hasDigit, isTrue);
      expect(rules.hasUppercase, isFalse);
      expect(rules.hasSpecial, isFalse);
      expect(rules.allPassed, isFalse);
      expect(AuthValidators.password('hoa12345'), weakMessage);
    });

    test('"Hoa@12345" hợp lệ, cả 4 điều kiện đạt', () {
      final rules = PasswordRules.of('Hoa@12345');
      expect(rules.hasMinLength, isTrue);
      expect(rules.hasUppercase, isTrue);
      expect(rules.hasDigit, isTrue);
      expect(rules.hasSpecial, isTrue);
      expect(rules.allPassed, isTrue);
      expect(AuthValidators.password('Hoa@12345'), isNull);
    });

    test('7 ký tự đủ các loại vẫn bị từ chối; 8 ký tự thì đạt', () {
      expect(AuthValidators.password('Ho@1234'), weakMessage); // 7 ký tự
      expect(PasswordRules.of('Ho@1234').hasMinLength, isFalse);
      expect(AuthValidators.password('Ho@12345'), isNull); // 8 ký tự
    });

    test('từng điều kiện riêng lẻ', () {
      expect(PasswordRules.of('').allPassed, isFalse);
      expect(PasswordRules.of('ABCDEFGH').hasUppercase, isTrue);
      expect(PasswordRules.of('ABCDEFGH').hasDigit, isFalse);
      expect(PasswordRules.of('abcdefg!').hasSpecial, isTrue);
      expect(PasswordRules.of('abcdefg!').hasUppercase, isFalse);
      expect(PasswordRules.of('Abcdefgh').hasSpecial, isFalse);
    });

    test('khoảng trắng không được tính là ký tự đặc biệt', () {
      expect(PasswordRules.of('Hoa 12345').hasSpecial, isFalse);
      expect(AuthValidators.password('Hoa 12345'), weakMessage);
    });

    test('mật khẩu không bị trim', () {
      expect(PasswordRules.of('Hoa@12  ').hasMinLength, isTrue);
    });
  });

  group('confirmPassword', () {
    test('rỗng', () {
      expect(
        AuthValidators.confirmPassword('', 'Hoa@12345'),
        'Vui lòng nhập lại mật khẩu.',
      );
    });

    test('"Hoa@12345" vs "hoa12345" -> không khớp (màn Đăng ký - Lỗi)', () {
      expect(
        AuthValidators.confirmPassword('Hoa@12345', 'hoa12345'),
        'Mật khẩu xác nhận không khớp với mật khẩu đã nhập.',
      );
    });

    test('khớp', () {
      expect(AuthValidators.confirmPassword('Hoa@12345', 'Hoa@12345'), isNull);
    });

    test('phân biệt hoa/thường', () {
      expect(
        AuthValidators.confirmPassword('hoa@12345', 'Hoa@12345'),
        'Mật khẩu xác nhận không khớp với mật khẩu đã nhập.',
      );
    });
  });

  group('agreement', () {
    test('chưa đồng ý', () {
      expect(
        AuthValidators.agreement(false),
        'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.',
      );
    });

    test('đã đồng ý', () {
      expect(AuthValidators.agreement(true), isNull);
    });
  });

  group('loginIdentifier', () {
    test('rỗng', () {
      expect(
        AuthValidators.loginIdentifier(''),
        'Vui lòng nhập số điện thoại hoặc email.',
      );
      expect(
        AuthValidators.loginIdentifier('   '),
        'Vui lòng nhập số điện thoại hoặc email.',
      );
    });

    test('số điện thoại -> chưa được hỗ trợ', () {
      const message =
          'Đăng nhập bằng số điện thoại chưa được hỗ trợ, vui lòng dùng email.';
      expect(AuthValidators.loginIdentifier('0912345678'), message);
      expect(AuthValidators.loginIdentifier('+84912345678'), message);
      expect(AuthValidators.loginIdentifier(' 0912345678 '), message);
    });

    test('email sai định dạng (kể cả chuỗi không phải số điện thoại)', () {
      const message =
          'Email không đúng định dạng tiêu chuẩn (ví dụ hợp lệ: '
          'name@example.com).';
      expect(AuthValidators.loginIdentifier('abc'), message);
      expect(AuthValidators.loginIdentifier('name@domain'), message);
      expect(AuthValidators.loginIdentifier('0912'), message); // SĐT thiếu số
    });

    test('email đúng', () {
      expect(AuthValidators.loginIdentifier('name@example.com'), isNull);
      expect(AuthValidators.loginIdentifier('  Name@Example.com '), isNull);
    });
  });

  group('loginPassword', () {
    test('rỗng', () {
      expect(AuthValidators.loginPassword(''), 'Vui lòng nhập mật khẩu.');
    });

    test('không áp quy tắc độ mạnh khi đăng nhập', () {
      expect(AuthValidators.loginPassword('a'), isNull);
      expect(AuthValidators.loginPassword('hoa12345'), isNull);
    });

    test('chuỗi toàn khoảng trắng vẫn tính là đã nhập (không trim)', () {
      expect(AuthValidators.loginPassword('   '), isNull);
    });
  });

  group('otp', () {
    const message = 'Vui lòng nhập đủ 6 chữ số của mã OTP.';

    test('6 chữ số hợp lệ', () {
      expect(AuthValidators.otp('123456'), isNull);
      expect(AuthValidators.otp('000000'), isNull);
    });

    test('thiếu hoặc thừa số (5 số, 7 số, rỗng)', () {
      expect(AuthValidators.otp(''), message);
      expect(AuthValidators.otp('12345'), message);
      expect(AuthValidators.otp('1234567'), message);
    });

    test('có chữ cái hoặc ký tự lạ', () {
      expect(AuthValidators.otp('12345a'), message);
      expect(AuthValidators.otp('abcdef'), message);
      expect(AuthValidators.otp('12 456'), message);
      expect(AuthValidators.otp('12.456'), message);
    });

    test('dấu +/- đứng đầu không phải chữ số (6 ký tự nhưng chỉ 5 số)', () {
      expect(AuthValidators.otp('+12345'), message);
      expect(AuthValidators.otp('-12345'), message);
    });
  });

  group('maskEmail', () {
    test('che phần tên, giữ 2 ký tự đầu', () {
      expect(AuthValidators.maskEmail('phuongha@gmail.com'), 'ph***@gmail.com');
    });

    test('tên 3 ký tự', () {
      expect(AuthValidators.maskEmail('abc@x.vn'), 'ab***@x.vn');
    });

    test('tên 1-2 ký tự chỉ giữ 1 ký tự đầu', () {
      expect(AuthValidators.maskEmail('a@x.vn'), 'a***@x.vn');
      expect(AuthValidators.maskEmail('ab@x.vn'), 'a***@x.vn');
    });

    test('chuỗi không có @ hoặc @ ở đầu thì trả về nguyên (đã trim)', () {
      expect(AuthValidators.maskEmail('khong-co-a-cong'), 'khong-co-a-cong');
      expect(AuthValidators.maskEmail('  khong-co  '), 'khong-co');
      expect(AuthValidators.maskEmail('@gmail.com'), '@gmail.com');
      expect(AuthValidators.maskEmail(''), '');
    });

    test('trim trước khi che', () {
      expect(
        AuthValidators.maskEmail('  phuongha@gmail.com '),
        'ph***@gmail.com',
      );
    });
  });
}
