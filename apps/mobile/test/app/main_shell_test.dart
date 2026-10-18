import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/screens/home_screen.dart';
import 'package:plant_flower_mobile/features/products/screens/product_catalog_screen.dart';

import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../support/controlled_product_repository.dart';
import '../support/finders.dart';
import '../support/product_test_app.dart';

const _comingSoon = 'Tính năng đang được phát triển.';
final _flowersKey = Key('catalog-category-${MockProductRepository.freshFlowers.id}');
final _plantsKey = Key('catalog-category-${MockProductRepository.plants.id}');

void main() {
  group('thanh điều hướng', () {
    testWidgets('hiện đủ 5 tab đúng thứ tự, mặc định ở Trang chủ', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      expect(MainTab.values.map((t) => t.label), [
        'Trang chủ',
        'Sản phẩm',
        'Chatbot',
        'Giỏ hàng',
        'Tài khoản',
      ]);
      for (final tab in MainTab.values) {
        expect(find.bySemanticsLabel(tab.label), findsOneWidget);
      }
      expect(currentTab(tester), MainTab.home);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('tab đang chọn dùng icon đặc, tab khác dùng icon viền', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);

      await tapNav(tester, MainTab.products);

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });

    testWidgets('initialTab chọn tab bắt đầu', (tester) async {
      await pumpMainShell(tester, initialTab: MainTab.products);
      await tester.pumpAndSettle();

      expect(currentTab(tester), MainTab.products);
      expect(find.byKey(const Key('catalog-search')), findsOneWidget);
    });

    testWidgets('chuyển qua lại giữa các tab', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      for (final tab in [
        MainTab.products,
        MainTab.chatbot,
        MainTab.cart,
        MainTab.account,
        MainTab.home,
      ]) {
        await tapNav(tester, tab);
        expect(currentTab(tester), tab, reason: tab.label);
      }
    });

    testWidgets('tab chưa làm hiện "Tính năng đang được phát triển."', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();
      expect(find.text(_comingSoon), findsNothing);

      for (final tab in [MainTab.chatbot, MainTab.cart, MainTab.account]) {
        await tapNav(tester, tab);
        expect(find.text(_comingSoon), findsOneWidget, reason: tab.label);
        // Tiêu đề của tab nằm trong nội dung (ngoài thanh điều hướng)
        expect(
          find.descendant(
            of: find.byType(Center),
            matching: find.text(tab.label),
          ),
          findsWidgets,
        );
      }

      await tapNav(tester, MainTab.home);
      expect(find.text(_comingSoon), findsNothing);
    });

    testWidgets('chạm lại tab đang chọn không đổi gì', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      await tapNav(tester, MainTab.home);

      expect(currentTab(tester), MainTab.home);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chuyển tab giữ nguyên trạng thái màn danh mục', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();
      await tapNav(tester, MainTab.products);

      await tester.enterText(find.byKey(const Key('catalog-search')), 'tulip');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-count')), findsOneWidget);

      await tapNav(tester, MainTab.chatbot);
      await tapNav(tester, MainTab.products);

      final field = tester.widget<TextField>(find.byKey(const Key('catalog-search')));
      expect(field.controller!.text, 'tulip');
      expect(textOf(tester, find.byKey(const Key('catalog-count'))), 'Hiển thị 1 tác phẩm');
    });

    testWidgets('có chấm thông báo ở tab Giỏ hàng khi showCartDot', (tester) async {
      Future<int> dots({required bool show}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AppBottomNav(
                current: MainTab.home,
                onSelected: (_) {},
                showCartDot: show,
              ),
            ),
          ),
        );
        return find
            .descendant(
              of: find.byType(AppBottomNav),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).color ==
                        AppColors.accentSoft,
              ),
            )
            .evaluate()
            .length;
      }

      expect(await dots(show: true), 1);
      expect(await dots(show: false), 0);
    });

    testWidgets('AppBottomNav gọi onSelected với đúng tab', (tester) async {
      final selected = <MainTab>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              current: MainTab.home,
              onSelected: selected.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Giỏ hàng'));
      await tester.tap(find.text('Tài khoản'));

      expect(selected, [MainTab.cart, MainTab.account]);
    });
  });

  group('hiệu năng', () {
    testWidgets(
      'tab Sản phẩm đang ẩn không giữ animation chạy khi đứng ở Trang chủ',
      (tester) async {
        // 45 sản phẩm => tab Sản phẩm còn trang kế nên footer có spinner
        final repo = MockProductRepository(
          latency: Duration.zero,
          categories: const [testCategory],
          products: generateProducts(45),
        );
        await pumpMainShell(tester, repository: repo);
        await pumpFrames(tester);

        expect(currentTab(tester), MainTab.home);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('MainShell.openCatalog', () {
    testWidgets('chuyển sang tab Sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(HomeScreen));
      MainShell.openCatalog(context);
      await tester.pumpAndSettle();

      expect(currentTab(tester), MainTab.products);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
    });

    testWidgets('chọn sẵn category được truyền vào', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();

      MainShell.openCatalog(
        tester.element(find.byType(HomeScreen)),
        categoryId: MockProductRepository.plants.id,
      );
      await tester.pumpAndSettle();

      expect(currentTab(tester), MainTab.products);
      expect(isChipSelected(tester, _plantsKey), isTrue);
      expect(isChipSelected(tester, const Key('catalog-category-all')), isFalse);
      expect(isChipSelected(tester, _flowersKey), isFalse);
      // Mock có 3 sản phẩm Cây cảnh
      expect(textOf(tester, find.byKey(const Key('catalog-count'))), 'Hiển thị 3 tác phẩm');
    });

    testWidgets('gọi lại với category khác hoặc null thì đổi theo', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(HomeScreen));

      MainShell.openCatalog(context, categoryId: MockProductRepository.plants.id);
      await tester.pumpAndSettle();
      expect(isChipSelected(tester, _plantsKey), isTrue);

      MainShell.openCatalog(context, categoryId: MockProductRepository.freshFlowers.id);
      await tester.pumpAndSettle();
      expect(isChipSelected(tester, _flowersKey), isTrue);
      expect(isChipSelected(tester, _plantsKey), isFalse);

      MainShell.openCatalog(context);
      await tester.pumpAndSettle();
      expect(isChipSelected(tester, const Key('catalog-category-all')), isTrue);
      expect(textOf(tester, find.byKey(const Key('catalog-count'))), 'Hiển thị 10 tác phẩm');
    });

    testWidgets('từ tab khác vẫn quay về Sản phẩm', (tester) async {
      await pumpMainShell(tester);
      await tester.pumpAndSettle();
      await tapNav(tester, MainTab.account);

      MainShell.openCatalog(
        tester.element(find.byType(IndexedStack)),
        categoryId: MockProductRepository.freshFlowers.id,
      );
      await tester.pumpAndSettle();

      expect(currentTab(tester), MainTab.products);
      expect(isChipSelected(tester, _flowersKey), isTrue);
    });

    testWidgets('màn danh mục trong shell không có nút quay lại', (tester) async {
      await pumpMainShell(tester, initialTab: MainTab.products);
      await tester.pumpAndSettle();

      expect(find.byType(ProductCatalogScreen), findsOneWidget);
      expect(find.byKey(const Key('catalog-back')), findsNothing);
    });
  });
}
