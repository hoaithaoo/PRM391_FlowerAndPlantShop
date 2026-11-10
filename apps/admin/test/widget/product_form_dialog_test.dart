import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/features/products/bloc/product_bloc.dart';
import 'package:plant_flower_admin/features/products/bloc/product_event.dart';
import 'package:plant_flower_admin/features/products/bloc/product_state.dart';
import 'package:plant_flower_admin/features/products/widgets/product_form_dialog.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockProductBloc extends Mock implements ProductBloc {}

void main() {
  group('ProductFormDialog Widget Tests', () {
    late MockProductBloc mockProductBloc;

    setUp(() {
      mockProductBloc = MockProductBloc();
      when(() => mockProductBloc.state).thenReturn(ProductInitial());
      when(() => mockProductBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    testWidgets('Renders image preview and image URL input field correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ProductBloc>.value(
              value: mockProductBloc,
              child: const ProductFormDialog(),
            ),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('Thêm sản phẩm mới'), findsOneWidget);
      expect(find.text('Chưa có ảnh sản phẩm'), findsOneWidget);
      expect(find.text('Đường dẫn hình ảnh (URL) *'), findsOneWidget);
      expect(find.text('Tên hoa / cây cảnh *'), findsOneWidget);
    });

    testWidgets('Populates existing imageUrl when editing product', (tester) async {
      const testProduct = ProductModel(
        id: 'p1',
        name: 'Hoa Hồng Đỏ',
        slug: 'hoa-hong-do',
        price: 150000,
        stock: 20,
        imageUrl: 'https://example.com/hoa-hong.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ProductBloc>.value(
              value: mockProductBloc,
              child: const ProductFormDialog(product: testProduct),
            ),
          ),
        ),
      );

      expect(find.text('Sửa thông tin sản phẩm'), findsOneWidget);
      expect(find.text('https://example.com/hoa-hong.jpg'), findsOneWidget);
    });

    testWidgets('Validates required and invalid URL format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ProductBloc>.value(
              value: mockProductBloc,
              child: const ProductFormDialog(),
            ),
          ),
        ),
      );

      // Scroll to submit button and tap
      final submitButton = find.text('Thêm mới');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập đường dẫn hình ảnh'), findsOneWidget);

      // Enter an invalid URL
      final urlInput = find.widgetWithText(TextFormField, 'Đường dẫn hình ảnh (URL) *');
      await tester.ensureVisible(urlInput);
      await tester.enterText(urlInput, 'invalid-url');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Đường dẫn phải bắt đầu bằng http:// hoặc https://'), findsOneWidget);
    });
  });
}
