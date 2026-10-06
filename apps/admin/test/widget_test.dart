import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_admin/main.dart';

void main() {
  testWidgets('Admin app smoke test renders login screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantFlowerAdminApp());
    expect(find.text('Nhà Có Hoa'), findsOneWidget);
    expect(find.text('Đăng nhập hệ thống'), findsOneWidget);
  });
}
