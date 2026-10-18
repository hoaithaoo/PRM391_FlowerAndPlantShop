import 'package:flutter/material.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import 'app/app.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/mock_product_repository.dart';
import 'features/products/data/product_repository.dart';

// Truyền qua --dart-define, ví dụ API_BASE_URL=http://10.0.2.2:4000
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final ProductRepository productRepository;
  if (_apiBaseUrl.isNotEmpty) {
    productRepository = ApiProductRepository(
      ProductsApi(ApiClient(baseUrl: _apiBaseUrl)),
    );
  } else {
    // Chưa cấu hình backend: chạy demo với dữ liệu giả
    debugPrint('API_BASE_URL chưa được cấu hình, dùng MockProductRepository.');
    productRepository = MockProductRepository();
  }

  runApp(PlantFlowerApp(productRepository: productRepository));
}
