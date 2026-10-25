import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_categories_service.dart';

class MockCategoriesService implements AdminCategoriesService {
  final List<CategoryModel> _mockCategories = [
    const CategoryModel(
      id: 'cat_sen',
      name: 'Sen & Súng Bản Địa',
      slug: 'sen-sung-ban-dia',
      sortOrder: 1,
    ),
    const CategoryModel(
      id: 'cat_dalat',
      name: 'Hoa Tươi Đà Lạt',
      slug: 'hoa-tuoi-da-lat',
      sortOrder: 2,
    ),
    const CategoryModel(
      id: 'cat_bonsai',
      name: 'Cây Cảnh Để Bàn & Phong Thủy',
      slug: 'cay-canh-phong-thuy',
      sortOrder: 3,
    ),
    const CategoryModel(
      id: 'cat_chau',
      name: 'Chậu Gốm Thủ Công',
      slug: 'chau-gom-thu-cong',
      sortOrder: 4,
    ),
  ];

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<CategoryModel>.from(_mockCategories);
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final slugExists = _mockCategories.any(
      (c) => c.slug.toLowerCase() == category.slug.toLowerCase(),
    );
    if (slugExists) {
      throw Exception('Đường dẫn tĩnh (Slug) đã tồn tại (CATEGORY_SLUG_EXISTS)');
    }
    final newCat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: category.name,
      slug: category.slug,
      description: category.description,
      imageUrl: category.imageUrl,
      sortOrder: category.sortOrder,
    );
    _mockCategories.add(newCat);
    return newCat;
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockCategories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      final slugExists = _mockCategories.any(
        (c) => c.id != category.id && c.slug.toLowerCase() == category.slug.toLowerCase(),
      );
      if (slugExists) {
        throw Exception('Đường dẫn tĩnh (Slug) đã tồn tại (CATEGORY_SLUG_EXISTS)');
      }
      _mockCategories[index] = category;
      return category;
    }
    throw Exception('Không tìm thấy danh mục (CATEGORY_NOT_FOUND)');
  }

  @override
  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (id == 'cat_sen' || id == 'cat_dalat' || id == 'cat_bonsai') {
      throw Exception('Không thể xóa danh mục đang có sản phẩm liên kết (CATEGORY_HAS_PRODUCTS)');
    }
    final index = _mockCategories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _mockCategories.removeAt(index);
      return;
    }
    throw Exception('Không tìm thấy danh mục (CATEGORY_NOT_FOUND)');
  }
}
