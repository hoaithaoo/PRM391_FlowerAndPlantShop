import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/categories/bloc/category_bloc.dart';
import 'package:plant_flower_admin/features/categories/bloc/category_event.dart';
import 'package:plant_flower_admin/features/categories/bloc/category_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('CategoryBloc Unit Tests', () {
    late MockAdminApiClient mockApiClient;
    late CategoryBloc categoryBloc;

    const testCategory = CategoryModel(
      id: 'cat_sen',
      name: 'Sen & Súng Bản Địa',
      slug: 'sen-sung-ban-dia',
      sortOrder: 1,
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      categoryBloc = CategoryBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      categoryBloc.close();
    });

    test('Trạng thái khởi tạo ban đầu phải là CategoryInitial', () {
      expect(categoryBloc.state, equals(CategoryInitial()));
    });

    blocTest<CategoryBloc, CategoryState>(
      'FetchCategoriesEvent tải danh sách danh mục thành công',
      build: () {
        when(() => mockApiClient.getCategories()).thenAnswer((_) async => [testCategory]);
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const FetchCategoriesEvent()),
      expect: () => [
        CategoryLoading(),
        const CategoryLoaded(categories: [testCategory]),
      ],
      verify: (_) {
        verify(() => mockApiClient.getCategories()).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'AddCategoryEvent thêm danh mục mới thành công và tải lại danh sách',
      build: () {
        when(() => mockApiClient.addCategory(testCategory)).thenAnswer((_) async => testCategory);
        when(() => mockApiClient.getCategories()).thenAnswer((_) async => [testCategory]);
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const AddCategoryEvent(testCategory)),
      expect: () => [
        const CategoryActionSuccess('Thêm danh mục mới thành công!'),
        CategoryLoading(),
        const CategoryLoaded(categories: [testCategory]),
      ],
      verify: (_) {
        verify(() => mockApiClient.addCategory(testCategory)).called(1);
        verify(() => mockApiClient.getCategories()).called(1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'AddCategoryEvent trùng slug emit CategoryError (CATEGORY_SLUG_EXISTS)',
      build: () {
        when(() => mockApiClient.addCategory(testCategory)).thenThrow(
          Exception('Mã/slug danh mục đã tồn tại (CATEGORY_SLUG_EXISTS)'),
        );
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const AddCategoryEvent(testCategory)),
      expect: () => [
        const CategoryError('Mã/slug danh mục đã tồn tại (CATEGORY_SLUG_EXISTS)'),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'DeleteCategoryEvent khi danh mục có sản phẩm liên kết emit CategoryError (CATEGORY_HAS_PRODUCTS)',
      build: () {
        when(() => mockApiClient.deleteCategory('cat_sen')).thenThrow(
          Exception('Không thể xóa: Danh mục đang có sản phẩm liên kết (CATEGORY_HAS_PRODUCTS)'),
        );
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const DeleteCategoryEvent('cat_sen')),
      expect: () => [
        const CategoryError(
          'Không thể xóa: Danh mục đang có sản phẩm liên kết (CATEGORY_HAS_PRODUCTS)',
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'DeleteCategoryEvent xóa thành công khi danh mục không có sản phẩm',
      build: () {
        when(() => mockApiClient.deleteCategory('cat_empty')).thenAnswer((_) async {});
        when(() => mockApiClient.getCategories()).thenAnswer((_) async => []);
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const DeleteCategoryEvent('cat_empty')),
      expect: () => [
        const CategoryActionSuccess('Đã xóa danh mục khỏi hệ thống!'),
        CategoryLoading(),
        const CategoryLoaded(categories: []),
      ],
      verify: (_) {
        verify(() => mockApiClient.deleteCategory('cat_empty')).called(1);
        verify(() => mockApiClient.getCategories()).called(1);
      },
    );
  });
}
