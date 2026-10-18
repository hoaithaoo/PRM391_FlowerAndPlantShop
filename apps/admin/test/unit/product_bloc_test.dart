import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/products/bloc/product_bloc.dart';
import 'package:plant_flower_admin/features/products/bloc/product_event.dart';
import 'package:plant_flower_admin/features/products/bloc/product_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('ProductBloc Unit Tests (PRM393 Testing Requirement)', () {
    late MockAdminApiClient mockApiClient;
    late ProductBloc productBloc;

    const testProduct = ProductModel(
      id: 'p1',
      name: 'Sen Hồng Tháp Mười',
      slug: 'sen-hong-thap-muoi',
      price: 390000,
      stock: 10,
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      productBloc = ProductBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      productBloc.close();
    });

    test('Trạng thái khởi tạo ban đầu phải là ProductInitial', () {
      expect(productBloc.state, equals(ProductInitial()));
    });

    blocTest<ProductBloc, ProductState>(
      'Phát ra [ProductLoading, ProductLoaded] khi FetchProductsEvent thành công',
      build: () {
        when(() => mockApiClient.getCategories()).thenAnswer((_) async => []);
        when(
          () => mockApiClient.getProducts(
            search: any(named: 'search'),
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => [testProduct]);
        return productBloc;
      },
      act: (bloc) => bloc.add(const FetchProductsEvent()),
      expect: () => [
        ProductLoading(),
        const ProductLoaded(
          products: [testProduct],
          categories: [],
          searchQuery: null,
          selectedCategory: null,
        ),
      ],
      verify: (_) {
        verify(() => mockApiClient.getCategories()).called(1);
        verify(() => mockApiClient.getProducts()).called(1);
      },
    );

    blocTest<ProductBloc, ProductState>(
      'Phát ra [ProductLoading, ProductError] khi FetchProductsEvent gặp lỗi',
      build: () {
        when(() => mockApiClient.getCategories()).thenThrow(Exception('Lỗi kết nối máy chủ'));
        return productBloc;
      },
      act: (bloc) => bloc.add(const FetchProductsEvent()),
      expect: () => [
        ProductLoading(),
        const ProductError('Lỗi kết nối máy chủ'),
      ],
    );
  });
}
