import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/data/product_repository.dart';
import 'package:plant_flower_mobile/features/products/state/product_catalog_controller.dart';
import 'package:plant_flower_mobile/features/products/state/product_catalog_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../../../support/controlled_product_repository.dart';

const _debounce = Duration(milliseconds: 400);

MockProductRepository _mockRepo({int count = 45}) => MockProductRepository(
  latency: Duration.zero,
  categories: const [testCategory, Category(id: 'cat-2', name: 'Cây cảnh')],
  products: [
    ...generateProducts(count),
  ],
);

ProductCatalogController _controller(
  ProductRepository repository, {
  String? initialCategoryId,
  int pageSize = 20,
}) {
  final controller = ProductCatalogController(
    repository: repository,
    initialCategoryId: initialCategoryId,
    pageSize: pageSize,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('initialize', () {
    test('trạng thái ban đầu là đang tải và không notify đồng bộ', () {
      final controller = _controller(_mockRepo());
      var notified = 0;
      controller.addListener(() => notified++);

      controller.initialize();

      expect(controller.state.status, CatalogStatus.loading);
      expect(notified, 0);
    });

    test('tải category và trang 1', () async {
      final repo = _mockRepo();
      final controller = _controller(repo);

      await controller.initialize();

      final state = controller.state;
      expect(state.status, CatalogStatus.ready);
      expect(state.categories.map((c) => c.id), ['cat-1', 'cat-2']);
      expect(state.items, hasLength(20));
      expect(state.total, 45);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);
      expect(state.loadingMore, isFalse);
      expect(repo.listProductsCalls, 1);
    });

    test('initialCategoryId được dùng cho request đầu', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo, initialCategoryId: 'cat-9');

      final init = controller.initialize();
      await pumpEventQueue();

      expect(controller.state.query.categoryId, 'cat-9');
      expect(repo.calls.single.query.categoryId, 'cat-9');
      repo.calls.single.complete(pageOf([summary('a')]));
      await init;
    });

    test('request đầu dùng pageSize và page 1', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo, pageSize: 7);

      final init = controller.initialize();
      await pumpEventQueue();

      expect(repo.calls.single.page, 1);
      expect(repo.calls.single.limit, 7);
      repo.calls.single.complete(pageOf([]));
      await init;
    });

    test('lỗi category không chặn danh sách', () async {
      final repo = ControlledProductRepository(
        categoriesError: const ProductFailure('lỗi category'),
      );
      final controller = _controller(repo);

      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls.single.complete(pageOf([summary('a')]));
      await init;

      expect(controller.state.status, CatalogStatus.ready);
      expect(controller.state.categories, isEmpty);
      expect(controller.state.items, hasLength(1));
    });

    test('kết quả rỗng thì isEmpty', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);

      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls.single.complete(pageOf([]));
      await init;

      expect(controller.state.isEmpty, isTrue);
      expect(controller.state.hasActiveFilters, isFalse);
    });
  });

  group('lỗi trang đầu', () {
    test('lỗi ProductFailure ở trang đầu', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);

      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls.single.fail(const ProductFailure('Mất mạng', offline: true));
      await init;

      expect(controller.state.status, CatalogStatus.error);
      expect(controller.state.error?.message, 'Mất mạng');
      expect(controller.state.error?.offline, isTrue);
      expect(controller.state.items, isEmpty);
    });

    test('lỗi không phải ProductFailure thành thông báo chung', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);

      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls.single.fail(StateError('boom'));
      await init;

      expect(controller.state.status, CatalogStatus.error);
      expect(controller.state.error?.message, isNotEmpty);
      expect(controller.state.error?.notFound, isFalse);
    });

    test('retry tải lại trang 1 và thoát trạng thái lỗi', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);

      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].fail(const ProductFailure('lỗi'));
      await init;
      expect(controller.state.status, CatalogStatus.error);

      final retry = controller.retry();
      await pumpEventQueue();
      expect(controller.state.status, CatalogStatus.loading);
      expect(controller.state.error, isNull);
      repo.calls[1].complete(pageOf([summary('a')]));
      await retry;

      expect(controller.state.status, CatalogStatus.ready);
      expect(controller.state.items.single.id, 'a');
    });

    test(
      'retry sau lỗi toàn màn cũng tải lại category đã lỗi trước đó',
      () async {
        final repo = ControlledProductRepository(
          categories: const [testCategory],
          categoriesError: const ProductFailure('offline', offline: true),
        );
        final controller = _controller(repo);

        final init = controller.initialize();
        await pumpEventQueue();
        repo.calls[0].fail(const ProductFailure('offline', offline: true));
        await init;
        expect(controller.state.categories, isEmpty);

        final retry = controller.retry();
        await pumpEventQueue();
        repo.calls[1].complete(pageOf([summary('a')]));
        await retry;

        // Kỳ vọng: sau khi thử lại thành công, chip danh mục xuất hiện.
        expect(controller.state.categories, [testCategory]);
      },
    );
  });

  group('tìm kiếm', () {
    test('gõ nhiều lần chỉ tạo 1 request sau debounce', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();
        expect(repo.listProductsCalls, 1);

        controller.setSearchText('s');
        async.elapse(const Duration(milliseconds: 100));
        controller.setSearchText('sa');
        async.elapse(const Duration(milliseconds: 100));
        controller.setSearchText('sản');
        async.elapse(const Duration(milliseconds: 300));
        // Chưa đủ 400ms kể từ lần gõ cuối
        async.flushMicrotasks();
        expect(repo.listProductsCalls, 1);

        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();
        expect(repo.listProductsCalls, 2);
        expect(controller.state.query.search, 'sản');
        expect(controller.state.status, CatalogStatus.ready);
      });
    });

    test('debounce mặc định là 400ms', () {
      expect(
        ProductCatalogController(repository: _mockRepo()).searchDebounce,
        _debounce,
      );
    });

    test('tìm xong trả về đúng kết quả và reset về trang 1', () {
      fakeAsync((async) {
        final controller = _controller(_mockRepo());
        controller.initialize();
        async.flushMicrotasks();
        // Sang trang 2 trước khi tìm
        controller.loadMore();
        async.flushMicrotasks();
        expect(controller.state.page, 2);

        controller.setSearchText('số 007');
        async.elapse(_debounce);
        async.flushMicrotasks();

        expect(controller.state.page, 1);
        expect(controller.state.items.map((e) => e.id), ['p007']);
        expect(controller.state.total, 1);
      });
    });

    test('gõ rồi xoá về giá trị cũ trước khi hết debounce thì không request', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();

        controller.setSearchText('abc');
        async.elapse(const Duration(milliseconds: 200));
        controller.setSearchText('');
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(repo.listProductsCalls, 1);
        expect(controller.state.query.search, isNull);
      });
    });

    test('text toàn khoảng trắng giống search hiện tại (null) nên bỏ qua', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();

        controller.setSearchText('    ');
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(repo.listProductsCalls, 1);
      });
    });

    test('gõ đúng từ khoá đang áp dụng thì không request lại', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        controller.submitSearch('007');
        async.flushMicrotasks();
        expect(repo.listProductsCalls, 2);

        controller.setSearchText('  007 ');
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(repo.listProductsCalls, 2);
      });
    });

    test('dispose huỷ timer debounce đang chờ', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = ProductCatalogController(repository: repo);
        controller.initialize();
        async.flushMicrotasks();

        controller.setSearchText('abc');
        controller.dispose();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(repo.listProductsCalls, 1);
      });
    });

    test('submitSearch áp dụng ngay, không chờ debounce', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();

        controller.submitSearch('hoa');
        async.flushMicrotasks();

        expect(repo.listProductsCalls, 2);
        expect(controller.state.query.search, 'hoa');
      });
    });

    test('submitSearch huỷ debounce đang chờ (không request lần hai)', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();

        controller.setSearchText('ab');
        async.elapse(const Duration(milliseconds: 100));
        controller.submitSearch('abc');
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(repo.listProductsCalls, 2);
        expect(controller.state.query.search, 'abc');
      });
    });

    test('search được trim; rỗng hoặc khoảng trắng thành null', () async {
      final controller = _controller(_mockRepo());
      await controller.initialize();

      controller.submitSearch('  số 007  ');
      expect(controller.state.query.search, 'số 007');

      controller.submitSearch('   ');
      expect(controller.state.query.search, isNull);

      controller.submitSearch('');
      expect(controller.state.query.search, isNull);
    });

    test('submit cùng từ khoá không tải lại', () async {
      final repo = _mockRepo();
      final controller = _controller(repo);
      await controller.initialize();

      controller.submitSearch('007');
      await pumpEventQueue();
      controller.submitSearch(' 007 ');
      await pumpEventQueue();

      expect(repo.listProductsCalls, 2);
    });
  });

  group('đổi bộ lọc luôn về trang 1', () {
    Future<ProductCatalogController> readyOnPage2(
      MockProductRepository repo,
    ) async {
      final controller = _controller(repo);
      await controller.initialize();
      await controller.loadMore();
      expect(controller.state.page, 2);
      expect(controller.state.items, hasLength(40));
      return controller;
    }

    test('selectCategory', () async {
      final controller = await readyOnPage2(_mockRepo());
      controller.selectCategory('cat-2');
      expect(controller.state.status, CatalogStatus.loading);
      expect(controller.state.items, isEmpty);
      await pumpEventQueue();

      expect(controller.state.query.categoryId, 'cat-2');
      expect(controller.state.page, 1);
      expect(controller.state.status, CatalogStatus.ready);
      // Toàn bộ sản phẩm sinh ra thuộc cat-1 nên cat-2 rỗng
      expect(controller.state.items, isEmpty);
    });

    test('selectCategory(null) quay về Tất cả', () async {
      final repo = _mockRepo();
      final controller = _controller(repo, initialCategoryId: 'cat-1');
      await controller.initialize();
      expect(controller.state.total, 45);

      controller.selectCategory(null);
      await pumpEventQueue();

      expect(controller.state.query.categoryId, isNull);
      expect(controller.state.total, 45);
    });

    test('chọn lại cùng category không tải lại', () async {
      final repo = _mockRepo();
      final controller = _controller(repo, initialCategoryId: 'cat-1');
      await controller.initialize();
      final before = repo.listProductsCalls;

      controller.selectCategory('cat-1');
      await pumpEventQueue();

      expect(repo.listProductsCalls, before);
    });

    test('setSort', () async {
      final controller = await readyOnPage2(_mockRepo());
      controller.setSort(ProductSort.priceDesc);
      await pumpEventQueue();

      expect(controller.state.page, 1);
      expect(controller.state.query.sort, ProductSort.priceDesc);
      expect(controller.state.items.first.id, 'p045');
      expect(controller.state.items, hasLength(20));
    });

    test('applyPriceFilter', () async {
      final controller = await readyOnPage2(_mockRepo());
      controller.applyPriceFilter(min: 100000, max: 200000);
      await pumpEventQueue();

      expect(controller.state.page, 1);
      expect(controller.state.query.minPrice, 100000);
      expect(controller.state.query.maxPrice, 200000);
      expect(controller.state.items.map((e) => e.price).toSet(), {
        for (var p = 100000; p <= 200000; p += 10000) p,
      });
      expect(controller.state.total, 11);
    });

    test('applyPriceFilter chỉ min hoặc chỉ max', () async {
      final controller = _controller(_mockRepo());
      await controller.initialize();

      controller.applyPriceFilter(min: 400000);
      await pumpEventQueue();
      expect(controller.state.query.maxPrice, isNull);
      expect(controller.state.total, 6);

      controller.applyPriceFilter(max: 50000);
      await pumpEventQueue();
      expect(controller.state.query.minPrice, isNull);
      expect(controller.state.total, 5);
    });

    test('applyPriceFilter bị bỏ qua khi min > max', () async {
      final repo = _mockRepo();
      final controller = _controller(repo);
      await controller.initialize();
      final before = repo.listProductsCalls;

      controller.applyPriceFilter(min: 500, max: 100);
      await pumpEventQueue();

      expect(repo.listProductsCalls, before);
      expect(controller.state.query.minPrice, isNull);
      expect(controller.state.query.maxPrice, isNull);
    });

    test('clearPriceFilter', () async {
      final controller = await readyOnPage2(_mockRepo());
      controller.applyPriceFilter(min: 100000, max: 200000);
      await pumpEventQueue();
      expect(controller.state.query.hasPriceFilter, isTrue);

      controller.clearPriceFilter();
      await pumpEventQueue();

      expect(controller.state.query.hasPriceFilter, isFalse);
      expect(controller.state.total, 45);
      expect(controller.state.page, 1);
    });

    test('resetFilters đưa mọi thứ về mặc định', () async {
      final controller = _controller(_mockRepo(), initialCategoryId: 'cat-1');
      await controller.initialize();
      controller.submitSearch('số');
      controller.applyPriceFilter(min: 1, max: 999999999);
      controller.setSort(ProductSort.priceAsc);
      await pumpEventQueue();
      expect(controller.state.hasActiveFilters, isTrue);

      controller.resetFilters();
      await pumpEventQueue();

      expect(controller.state.query, const ProductQuery());
      expect(controller.state.hasActiveFilters, isFalse);
      expect(controller.state.total, 45);
    });

    test('resetFilters huỷ debounce đang chờ', () {
      fakeAsync((async) {
        final repo = _mockRepo();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();

        controller.setSearchText('abc');
        controller.resetFilters();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(controller.state.query.search, isNull);
        expect(repo.listProductsCalls, 1);
      });
    });

    test('hasActiveFilters phản ánh từng loại bộ lọc', () async {
      final controller = _controller(_mockRepo());
      await controller.initialize();
      expect(controller.state.hasActiveFilters, isFalse);

      controller.setSort(ProductSort.priceAsc);
      expect(controller.state.hasActiveFilters, isTrue);
      controller.setSort(ProductSort.newest);
      expect(controller.state.hasActiveFilters, isFalse);

      controller.selectCategory('cat-2');
      expect(controller.state.hasActiveFilters, isTrue);
      controller.selectCategory(null);
      expect(controller.state.hasActiveFilters, isFalse);
      await pumpEventQueue();
    });
  });

  group('loadMore', () {
    test('nối trang, cập nhật page/hasMore cho đến hết', () async {
      final repo = _mockRepo();
      final controller = _controller(repo);
      await controller.initialize();

      await controller.loadMore();
      expect(controller.state.items, hasLength(40));
      expect(controller.state.page, 2);
      expect(controller.state.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.state.items, hasLength(45));
      expect(controller.state.page, 3);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.total, 45);
      // Thứ tự theo trang, không trùng
      expect(controller.state.items.map((e) => e.id).toSet(), hasLength(45));
      expect(controller.state.items.first.id, 'p001');
      expect(controller.state.items.last.id, 'p045');
    });

    test('không chạy khi đã hết trang', () async {
      final repo = _mockRepo(count: 12);
      final controller = _controller(repo);
      await controller.initialize();
      expect(controller.state.hasMore, isFalse);
      final before = repo.listProductsCalls;

      await controller.loadMore();

      expect(repo.listProductsCalls, before);
      expect(controller.state.items, hasLength(12));
    });

    test('không chạy khi chưa có dữ liệu trang đầu', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();

      await controller.loadMore();

      expect(repo.calls, hasLength(1));
      repo.calls.single.complete(pageOf([], totalPages: 0));
      await init;
    });

    test('gọi liên tiếp khi đang tải chỉ tạo 1 request', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a'), summary('b')], total: 4, totalPages: 2),
      );
      await init;

      final first = controller.loadMore();
      final second = controller.loadMore();
      await pumpEventQueue();

      expect(controller.state.loadingMore, isTrue);
      expect(repo.calls, hasLength(2));
      expect(repo.calls[1].page, 2);
      repo.calls[1].complete(
        pageOf([summary('c'), summary('d')], page: 2, total: 4, totalPages: 2),
      );
      await Future.wait([first, second]);

      expect(controller.state.items.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(controller.state.loadingMore, isFalse);
    });

    test('bỏ qua sản phẩm trùng id giữa các trang', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a'), summary('b')], total: 4, totalPages: 2),
      );
      await init;

      final more = controller.loadMore();
      await pumpEventQueue();
      repo.calls[1].complete(
        pageOf([summary('b'), summary('c')], page: 2, total: 4, totalPages: 2),
      );
      await more;

      expect(controller.state.items.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('lỗi tải thêm giữ danh sách, đặt loadMoreError, chặn loadMore tự động', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a')], total: 3, totalPages: 3),
      );
      await init;

      final more = controller.loadMore();
      await pumpEventQueue();
      repo.calls[1].fail(const ProductFailure('Rớt mạng', offline: true));
      await more;

      final state = controller.state;
      expect(state.status, CatalogStatus.ready);
      expect(state.items.map((e) => e.id), ['a']);
      expect(state.loadingMore, isFalse);
      expect(state.loadMoreError?.message, 'Rớt mạng');
      expect(state.canLoadMore, isFalse);

      // loadMore tự động không chạy lại khi đang lỗi
      await controller.loadMore();
      expect(repo.calls, hasLength(2));
    });

    test('retryLoadMore thử lại đúng trang đang lỗi và xoá lỗi', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a')], total: 2, totalPages: 2),
      );
      await init;
      final more = controller.loadMore();
      await pumpEventQueue();
      repo.calls[1].fail(const ProductFailure('lỗi'));
      await more;

      final retry = controller.retryLoadMore();
      await pumpEventQueue();
      expect(repo.calls, hasLength(3));
      expect(repo.calls[2].page, 2);
      expect(controller.state.loadMoreError, isNull);
      expect(controller.state.loadingMore, isTrue);
      repo.calls[2].complete(
        pageOf([summary('b')], page: 2, total: 2, totalPages: 2),
      );
      await retry;

      expect(controller.state.items.map((e) => e.id), ['a', 'b']);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.loadMoreError, isNull);
    });

    test('retryLoadMore không làm gì khi hết trang', () async {
      final repo = _mockRepo(count: 5);
      final controller = _controller(repo);
      await controller.initialize();
      final before = repo.listProductsCalls;

      await controller.retryLoadMore();

      expect(repo.listProductsCalls, before);
    });

    test('đổi bộ lọc trong lúc tải thêm: kết quả trang cũ bị bỏ', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a'), summary('b')], total: 4, totalPages: 2),
      );
      await init;

      final more = controller.loadMore();
      await pumpEventQueue();
      controller.selectCategory('cat-2');
      await pumpEventQueue();
      expect(repo.calls, hasLength(3));

      // Trang 2 của bộ lọc cũ về muộn
      repo.calls[1].complete(
        pageOf([summary('c'), summary('d')], page: 2, total: 4, totalPages: 2),
      );
      await more;
      expect(controller.state.items, isEmpty);
      expect(controller.state.status, CatalogStatus.loading);

      repo.calls[2].complete(pageOf([summary('x')]));
      await pumpEventQueue();
      expect(controller.state.items.map((e) => e.id), ['x']);
      expect(controller.state.page, 1);
    });
  });

  group('race: response cũ về muộn', () {
    test('lọc A rồi B; A về sau B thì A bị bỏ', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(pageOf([summary('init')]));
      await init;

      controller.selectCategory('A');
      await pumpEventQueue();
      controller.selectCategory('B');
      await pumpEventQueue();
      expect(repo.calls, hasLength(3));

      repo.calls[2].complete(pageOf([summary('from-b')]));
      await pumpEventQueue();
      expect(controller.state.items.map((e) => e.id), ['from-b']);

      repo.calls[1].complete(pageOf([summary('from-a')], total: 99));
      await pumpEventQueue();

      expect(controller.state.query.categoryId, 'B');
      expect(controller.state.items.map((e) => e.id), ['from-b']);
      expect(controller.state.total, 1);
    });

    test('lỗi của request cũ về muộn không ghi đè kết quả mới', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(pageOf([summary('init')]));
      await init;

      controller.selectCategory('A');
      await pumpEventQueue();
      controller.selectCategory('B');
      await pumpEventQueue();
      repo.calls[2].complete(pageOf([summary('from-b')]));
      await pumpEventQueue();

      repo.calls[1].fail(const ProductFailure('lỗi cũ'));
      await pumpEventQueue();

      expect(controller.state.status, CatalogStatus.ready);
      expect(controller.state.error, isNull);
      expect(controller.state.items.map((e) => e.id), ['from-b']);
    });

    test('request đầu tiên về muộn sau khi người dùng đã đổi bộ lọc', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();

      controller.selectCategory('A');
      await pumpEventQueue();
      repo.calls[1].complete(pageOf([summary('from-a')]));
      await pumpEventQueue();

      repo.calls[0].complete(pageOf([summary('stale')], total: 50));
      await init;

      expect(controller.state.items.map((e) => e.id), ['from-a']);
      expect(controller.state.total, 1);
    });

    test('gõ tìm kiếm liên tiếp: chỉ kết quả của từ khoá cuối được giữ', () {
      fakeAsync((async) {
        final repo = ControlledProductRepository();
        final controller = _controller(repo);
        controller.initialize();
        async.flushMicrotasks();
        repo.calls[0].complete(pageOf([summary('init')]));
        async.flushMicrotasks();

        controller.submitSearch('a');
        async.flushMicrotasks();
        controller.submitSearch('ab');
        async.flushMicrotasks();
        expect(repo.calls, hasLength(3));

        repo.calls[2].complete(pageOf([summary('ab-1')]));
        async.flushMicrotasks();
        repo.calls[1].complete(pageOf([summary('a-1'), summary('a-2')]));
        async.flushMicrotasks();

        expect(controller.state.query.search, 'ab');
        expect(controller.state.items.map((e) => e.id), ['ab-1']);
      });
    });
  });

  group('refresh', () {
    Future<(ControlledProductRepository, ProductCatalogController)>
    readyController() async {
      final repo = ControlledProductRepository(categories: const [testCategory]);
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a'), summary('b')], total: 2),
      );
      await init;
      return (repo, controller);
    }

    test('giữ danh sách cũ cho tới khi có kết quả mới', () async {
      final (repo, controller) = await readyController();

      final refresh = controller.refresh();
      await pumpEventQueue();
      expect(controller.state.items.map((e) => e.id), ['a', 'b']);
      expect(controller.state.status, CatalogStatus.ready);

      repo.calls[1].complete(pageOf([summary('c')], total: 1));
      expect(await refresh, isTrue);

      expect(controller.state.items.map((e) => e.id), ['c']);
      expect(controller.state.total, 1);
      expect(controller.state.page, 1);
    });

    test('thất bại trả false và giữ danh sách cũ', () async {
      final (repo, controller) = await readyController();

      final refresh = controller.refresh();
      await pumpEventQueue();
      repo.calls[1].fail(const ProductFailure('lỗi'));

      expect(await refresh, isFalse);
      expect(controller.state.status, CatalogStatus.ready);
      expect(controller.state.items.map((e) => e.id), ['a', 'b']);
      expect(controller.state.error, isNull);
    });

    test('thất bại khi chưa có item thì chuyển sang trạng thái lỗi', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(pageOf([]));
      await init;

      final refresh = controller.refresh();
      await pumpEventQueue();
      repo.calls[1].fail(const ProductFailure('lỗi mới'));

      expect(await refresh, isFalse);
      expect(controller.state.status, CatalogStatus.error);
      expect(controller.state.error?.message, 'lỗi mới');
    });

    test('tải lại category nếu trước đó đang rỗng', () async {
      final repo = ControlledProductRepository(
        categories: const [testCategory],
        categoriesError: const ProductFailure('lỗi'),
      );
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(pageOf([summary('a')]));
      await init;
      expect(controller.state.categories, isEmpty);

      final refresh = controller.refresh();
      await pumpEventQueue();
      repo.calls[1].complete(pageOf([summary('a')]));
      await refresh;

      expect(controller.state.categories, [testCategory]);
      expect(repo.listCategoriesCalls, 2);
    });

    test('đang tải thêm thì refresh xoá trạng thái loadingMore', () async {
      final repo = ControlledProductRepository();
      final controller = _controller(repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a')], total: 2, totalPages: 2),
      );
      await init;

      final more = controller.loadMore();
      await pumpEventQueue();
      expect(controller.state.loadingMore, isTrue);

      final refresh = controller.refresh();
      await pumpEventQueue();
      expect(controller.state.loadingMore, isFalse);

      // Trang 2 cũ về muộn bị bỏ, refresh thành công
      repo.calls[1].complete(
        pageOf([summary('stale')], page: 2, total: 2, totalPages: 2),
      );
      await more;
      repo.calls[2].complete(
        pageOf([summary('fresh')], total: 2, totalPages: 2),
      );
      await refresh;

      expect(controller.state.items.map((e) => e.id), ['fresh']);
      expect(controller.state.page, 1);
    });
  });

  group('refresh khi đang gõ tìm kiếm', () {
    test(
      'từ khoá đang chờ debounce không bị mất khi kéo để làm mới',
      () {
        fakeAsync((async) {
          final repo = _mockRepo();
          final controller = _controller(repo);
          controller.initialize();
          async.flushMicrotasks();

          // Ô tìm kiếm đang hiện "tulip" nhưng debounce chưa chạy xong
          controller.setSearchText('tulip');
          controller.refresh();
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 2));
          async.flushMicrotasks();

          // Kỳ vọng: danh sách khớp với chữ trong ô tìm kiếm
          expect(controller.state.query.search, 'tulip');
        });
      },
    );
  });

  group('dispose', () {
    test('request về sau dispose không notify và không ném lỗi', () async {
      final repo = ControlledProductRepository();
      final controller = ProductCatalogController(repository: repo);
      var notified = 0;
      controller.addListener(() => notified++);
      final init = controller.initialize();
      await pumpEventQueue();
      // Category đã tải xong (và đã notify) trước khi dispose
      notified = 0;

      controller.dispose();
      repo.calls.single.complete(pageOf([summary('a')]));
      await init;

      expect(notified, 0);
    });

    test('lỗi về sau dispose cũng bị bỏ qua', () async {
      final repo = ControlledProductRepository();
      final controller = ProductCatalogController(repository: repo);
      final init = controller.initialize();
      await pumpEventQueue();

      controller.dispose();
      repo.calls.single.fail(const ProductFailure('lỗi'));
      await init;
    });

    test('loadMore/refresh về sau dispose không notify', () async {
      final repo = ControlledProductRepository();
      final controller = ProductCatalogController(repository: repo);
      final init = controller.initialize();
      await pumpEventQueue();
      repo.calls[0].complete(
        pageOf([summary('a')], total: 2, totalPages: 2),
      );
      await init;
      final more = controller.loadMore();
      await pumpEventQueue();
      final refresh = controller.refresh();
      await pumpEventQueue();

      controller.dispose();
      repo.calls[1].complete(
        pageOf([summary('b')], page: 2, total: 2, totalPages: 2),
      );
      repo.calls[2].complete(pageOf([summary('c')], total: 2, totalPages: 2));
      await more;
      await refresh;
    });
  });

  group('notify', () {
    test('đổi bộ lọc notify trạng thái loading rồi ready', () async {
      final controller = _controller(_mockRepo());
      await controller.initialize();
      final statuses = <CatalogStatus>[];
      controller.addListener(() => statuses.add(controller.state.status));

      controller.setSort(ProductSort.priceAsc);
      await pumpEventQueue();

      // Notify đổi query, rồi loading, rồi ready
      expect(statuses.length, greaterThanOrEqualTo(2));
      expect(statuses.contains(CatalogStatus.loading), isTrue);
      expect(statuses.last, CatalogStatus.ready);
    });
  });
}
