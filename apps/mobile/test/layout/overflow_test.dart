import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/widgets/home/home_story_card.dart';

import '../support/overflow_scenarios.dart';
import '../support/product_test_app.dart';

void main() {
  defineOverflowScenarios('360x800', size: const Size(360, 800));
  defineOverflowScenarios('430x800', size: const Size(430, 800));
  defineOverflowScenarios(
    '390x844 chữ phóng to 1.3',
    size: designSize,
    textScale: 1.3,
  );

  group('vùng an toàn (tai thỏ, thanh điều hướng hệ thống)', () {
    Future<void> configure(WidgetTester tester) async {
      tester.view.physicalSize = designSize;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.reset);
    }

    testWidgets('Trang chủ không tràn và thẻ cuối không bị thanh điều hướng che', (tester) async {
      await configure(tester);
      await pumpMainShell(tester);
      await scrollThrough(tester, homeScrollable, label: 'home safe area');

      await tester.drag(homeScrollable, const Offset(0, -100000));
      await tester.pumpAndSettle();
      final story = tester.getRect(
        find
            .descendant(
              of: find.byType(HomeStoryCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final nav = tester.getRect(find.byType(AppBottomNav));
      expect(story.bottom, lessThanOrEqualTo(nav.top));
      // Header không bị tai thỏ che
      expect(
        tester.getTopLeft(find.byKey(const Key('header-notifications'))).dy,
        greaterThanOrEqualTo(47),
      );
    });

    testWidgets('Danh mục: footer không bị thanh điều hướng che', (tester) async {
      await configure(tester);
      await pumpMainShell(tester, initialTab: MainTab.products);
      await scrollThrough(tester, catalogScrollable, label: 'catalog safe area');

      await tester.drag(catalogScrollable, const Offset(0, -100000));
      await tester.pumpAndSettle();
      final top = tester.getRect(find.byKey(const Key('catalog-scroll-top')));
      final nav = tester.getRect(find.byType(AppBottomNav));
      expect(top.bottom, lessThanOrEqualTo(nav.top));
    });

    testWidgets('Chi tiết: thanh mua hàng chừa vùng an toàn phía dưới', (tester) async {
      await configure(tester);
      await openDetailScreen(
        tester,
        createTestRepository(),
        MockProductRepository.defaultProducts.first.id,
      );
      await scrollThrough(
        tester,
        find.byKey(const Key('detail-scroll')),
        label: 'detail safe area',
      );

      final button = tester.getRect(find.byKey(const Key('detail-add-to-cart')));
      expect(button.bottom, lessThanOrEqualTo(designSize.height - 34));
      final header = tester.getRect(find.byKey(const Key('detail-header')));
      expect(header.height, 64 + 47);
    });
  });
}
