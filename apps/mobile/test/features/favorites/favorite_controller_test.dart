import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/favorites/data/mock_favorite_repository.dart';
import 'package:plant_flower_mobile/features/favorites/state/favorite_controller.dart';

class _GatedRepository extends MockFavoriteRepository {
  _GatedRepository({super.initialIds});

  final addResult = Completer<void>();
  final removeResult = Completer<void>();

  @override
  Future<void> add(String productId) => addResult.future;
  @override
  Future<void> remove(String productId) => removeResult.future;
}

void main() {
  test('load lấy ID và ids không cho bên ngoài sửa', () async {
    final controller = FavoriteController(
      repository: MockFavoriteRepository(initialIds: ['one']),
    );
    addTearDown(controller.dispose);
    expect(await controller.load(), isTrue);
    expect(controller.ids, {'one'});
    expect(() => controller.ids.add('two'), throwsUnsupportedError);
  });

  test('thêm lạc quan, chặn yêu cầu trùng và hoàn tác khi API lỗi', () async {
    final repository = _GatedRepository();
    final controller = FavoriteController(repository: repository);
    addTearDown(controller.dispose);
    var changes = 0;
    controller.addListener(() => changes++);
    final result = controller.toggle('one');
    expect(controller.isFavorite('one'), isTrue);
    expect(changes, 1);
    // Bấm lại khi request trước chưa xong: bỏ qua (không báo lỗi), trạng thái giữ nguyên.
    expect(await controller.toggle('one'), isTrue);
    expect(controller.isFavorite('one'), isTrue);
    expect(changes, 1);
    repository.addResult.completeError(Exception('Mất mạng'));
    expect(await result, isFalse);
    expect(controller.isFavorite('one'), isFalse);
    expect(changes, 2);
  });

  test('bỏ lạc quan và hoàn tác khi API lỗi', () async {
    final repository = _GatedRepository(initialIds: ['one']);
    final controller = FavoriteController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();
    final result = controller.toggle('one');
    expect(controller.ids, isEmpty);
    repository.removeResult.completeError(Exception('Mất mạng'));
    expect(await result, isFalse);
    expect(controller.ids, {'one'});
  });

  test('thêm và bỏ thành công giữ đồng bộ với kho', () async {
    final repository = MockFavoriteRepository();
    final controller = FavoriteController(repository: repository);
    addTearDown(controller.dispose);
    expect(await controller.toggle('one'), isTrue);
    expect(await repository.listIds(), {'one'});
    expect(await controller.toggle('one'), isTrue);
    expect(await repository.listIds(), isEmpty);
  });

  test('reset không nhận lại kết quả thao tác của phiên cũ', () async {
    final repository = _GatedRepository(initialIds: ['one']);
    final controller = FavoriteController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();
    final result = controller.toggle('one');
    controller.reset();
    repository.removeResult.completeError(Exception('Phiên cũ'));
    expect(await result, isFalse);
    expect(controller.ids, isEmpty);
  });

  test('load về muộn không ghi đè thao tác lạc quan', () async {
    final repository = _LoadRepository();
    final controller = FavoriteController(repository: repository);
    addTearDown(controller.dispose);
    final load = controller.load();
    await controller.toggle('one');
    repository.result.complete(<String>{});
    await load;
    expect(controller.ids, {'one'});
  });

  test('reset và dispose không nhận kết quả load của phiên cũ', () async {
    for (final dispose in [false, true]) {
      final repository = _LoadRepository();
      final controller = FavoriteController(repository: repository);
      final load = controller.load();
      if (dispose) {
        controller.dispose();
      } else {
        controller.reset();
      }
      repository.result.complete({'old'});
      expect(await load, isFalse);
      expect(controller.ids, isEmpty);
      if (!dispose) controller.dispose();
    }
  });
}

class _LoadRepository extends MockFavoriteRepository {
  final result = Completer<Set<String>>();
  @override
  Future<Set<String>> listIds() => result.future;
}
