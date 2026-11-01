import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_products_service.dart';

class MockProductsService implements AdminProductsService {
  final List<ProductModel> _mockProducts = [
    const ProductModel(
      id: 'p1',
      name: 'Sen Hồng Tháp Mười (Bình Gốm Đất Nung)',
      slug: 'sen-hong-thap-muoi',
      description:
          'Sen bách diệp hái sớm từ Đồng Tháp, chưng bền 5-7 ngày với hương thanh tao.',
      price: 450000,
      salePrice: 390000,
      stock: 12,
      categoryId: 'cat_sen',
      categoryName: 'Sen & Súng Bản Địa',
      imageUrl:
          'https://images.unsplash.com/photo-1508615039623-a25605d2b022?w=500',
    ),
    const ProductModel(
      id: 'p2',
      name: 'Bó Cẩm Tú Cầu Xanh Lam Đà Lạt',
      slug: 'cam-tu-cau-da-lat',
      description:
          'Cẩm tú cầu nhập trực tiếp từ vườn Lạc Dương, cành to nở rộ tươi mới.',
      price: 320000,
      stock: 8,
      categoryId: 'cat_dalat',
      categoryName: 'Hoa Tươi Đà Lạt',
      imageUrl:
          'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
    ),
    const ProductModel(
      id: 'p3',
      name: 'Cây Kim Tiền Chiêu Tài (Chậu Gốm Men Mát)',
      slug: 'cay-kim-tien',
      description:
          'Cây lọc không khí và mang lại may mắn cho văn phòng, bàn làm việc.',
      price: 250000,
      salePrice: 220000,
      stock: 3, // Low stock indicator
      categoryId: 'cat_bonsai',
      categoryName: 'Cây Cảnh Để Bàn & Phong Thủy',
      imageUrl:
          'https://images.unsplash.com/photo-1512428813834-c702c7702b78?w=500',
    ),
    const ProductModel(
      id: 'p4',
      name: 'Bó Hoa Hướng Dương Nắng Mới',
      slug: 'huong-duong-nang-moi',
      description: '5 cành hướng dương phối hoa sao tím và lá phụ cao cấp.',
      price: 280000,
      stock: 15,
      categoryId: 'cat_dalat',
      categoryName: 'Hoa Tươi Đà Lạt',
      imageUrl:
          'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=500',
    ),
  ];

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? search,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = List<ProductModel>.from(_mockProducts);
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newProduct = product.copyWith(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
    );
    _mockProducts.insert(0, newProduct);
    return newProduct;
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _mockProducts[index] = product;
      return product;
    }
    throw Exception('Không tìm thấy sản phẩm (PRODUCT_NOT_FOUND)');
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockProducts.indexWhere((p) => p.id == id);
    if (index != -1) {
      _mockProducts.removeAt(index);
      return;
    }
    throw Exception('Không tìm thấy sản phẩm (PRODUCT_NOT_FOUND)');
  }
}
