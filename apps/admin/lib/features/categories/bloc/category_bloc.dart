import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/admin_api_client.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final AdminApiClient apiClient;

  CategoryBloc({required this.apiClient}) : super(CategoryInitial()) {
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final categories = await apiClient.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await apiClient.addCategory(event.category);
      emit(const CategoryActionSuccess('Thêm danh mục mới thành công!'));
      add(const FetchCategoriesEvent());
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await apiClient.updateCategory(event.category);
      emit(const CategoryActionSuccess('Cập nhật thông tin danh mục thành công!'));
      add(const FetchCategoriesEvent());
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await apiClient.deleteCategory(event.categoryId);
      emit(const CategoryActionSuccess('Đã xóa danh mục khỏi hệ thống!'));
      add(const FetchCategoriesEvent());
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
