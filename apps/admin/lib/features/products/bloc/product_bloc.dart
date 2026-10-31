import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/admin_api_client.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final AdminApiClient apiClient;

  ProductBloc({required this.apiClient}) : super(ProductInitial()) {
    on<FetchProductsEvent>(_onFetchProducts);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  Future<void> _onFetchProducts(FetchProductsEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final categories = await apiClient.getCategories();
      final products = await apiClient.getProducts(
        search: event.search,
        categoryId: event.categoryId,
      );
      emit(ProductLoaded(
        products: products,
        categories: categories,
        selectedCategory: event.categoryId,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(ProductError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddProduct(AddProductEvent event, Emitter<ProductState> emit) async {
    try {
      await apiClient.addProduct(event.product);
      emit(const ProductActionSuccess('Thêm sản phẩm mới thành công!'));
      add(const FetchProductsEvent());
    } catch (e) {
      emit(ProductError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateProduct(UpdateProductEvent event, Emitter<ProductState> emit) async {
    try {
      await apiClient.updateProduct(event.product);
      emit(const ProductActionSuccess('Cập nhật thông tin sản phẩm thành công!'));
      add(const FetchProductsEvent());
    } catch (e) {
      emit(ProductError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteProduct(DeleteProductEvent event, Emitter<ProductState> emit) async {
    try {
      await apiClient.deleteProduct(event.productId);
      emit(const ProductActionSuccess('Đã xóa sản phẩm khỏi hệ thống!'));
      add(const FetchProductsEvent());
    } catch (e) {
      emit(ProductError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
