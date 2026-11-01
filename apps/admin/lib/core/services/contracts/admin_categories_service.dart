import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminCategoriesService {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> addCategory(CategoryModel category);
  Future<CategoryModel> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}
