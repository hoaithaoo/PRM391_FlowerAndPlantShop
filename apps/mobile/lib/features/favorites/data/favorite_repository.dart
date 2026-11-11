import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class FavoriteRepository {
  Future<Set<String>> listIds();
  Future<List<ProductSummary>> list();
  Future<void> add(String productId);
  Future<void> remove(String productId);
}

/// Giữ mã lỗi backend để có thể phân biệt lỗi xác thực và lỗi mạng.
class FavoriteFailure implements Exception {
  const FavoriteFailure(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;
}
