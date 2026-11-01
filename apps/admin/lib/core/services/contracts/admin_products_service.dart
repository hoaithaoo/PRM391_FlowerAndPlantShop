import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminProductsService {
  Future<List<ProductModel>> getProducts({String? categoryId, String? search});
  Future<ProductModel> addProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}
