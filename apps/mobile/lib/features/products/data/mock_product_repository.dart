import 'package:plant_flower_shared/plant_flower_shared.dart';

import 'product_repository.dart';

/// Dữ liệu giả khi chưa cấu hình `API_BASE_URL` (và dùng cho test).
///
/// Lọc, sắp xếp và phân trang giống backend để màn hình chạy y như API thật.
class MockProductRepository implements ProductRepository {
  MockProductRepository({
    this.latency = const Duration(milliseconds: 400),
    List<Category>? categories,
    List<ProductDetail>? products,
  }) : categories = categories ?? defaultCategories,
       products = products ?? defaultProducts;

  /// Độ trễ giả lập; test đặt [Duration.zero].
  final Duration latency;
  final List<Category> categories;
  final List<ProductDetail> products;

  /// Đặt khác null để lần gọi kế tiếp ném lỗi (dùng trong test).
  ProductFailure? nextFailure;

  /// Số lần [listProducts] được gọi (dùng trong test).
  int listProductsCalls = 0;

  @override
  Future<List<Category>> listCategories() async {
    await _wait();
    return List.unmodifiable(categories);
  }

  @override
  Future<PagedResult<ProductSummary>> listProducts(
    ProductQuery query, {
    int page = 1,
    int limit = 20,
  }) async {
    listProductsCalls++;
    await _wait();
    final keyword = query.search?.trim().toLowerCase() ?? '';
    final filtered =
        products.where((product) {
          if (!product.isActive) return false;
          if (query.categoryId != null &&
              product.category.id != query.categoryId) {
            return false;
          }
          if (keyword.isNotEmpty &&
              !product.name.toLowerCase().contains(keyword) &&
              !product.sku.toLowerCase().contains(keyword)) {
            return false;
          }
          if (query.minPrice != null && product.price < query.minPrice!) {
            return false;
          }
          if (query.maxPrice != null && product.price > query.maxPrice!) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) {
          final byKey = switch (query.sort) {
            ProductSort.priceAsc => a.price.compareTo(b.price),
            ProductSort.priceDesc => b.price.compareTo(a.price),
            // Danh sách mặc định đã xếp mới nhất trước
            ProductSort.newest =>
              products.indexOf(a).compareTo(products.indexOf(b)),
          };
          return byKey != 0 ? byKey : a.id.compareTo(b.id);
        });

    final start = (page - 1) * limit;
    final pageItems = filtered.skip(start).take(limit).map(_toSummary).toList();
    return PagedResult(
      items: pageItems,
      page: page,
      total: filtered.length,
      totalPages: (filtered.length / limit).ceil(),
    );
  }

  @override
  Future<ProductDetail> getProduct(String id) async {
    await _wait();
    for (final product in products) {
      if (product.id == id && product.isActive) return product;
    }
    throw const ProductFailure(
      'Sản phẩm không tồn tại hoặc đã ngừng bán.',
      notFound: true,
    );
  }

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
  }

  static ProductSummary _toSummary(ProductDetail product) => ProductSummary(
    id: product.id,
    sku: product.sku,
    name: product.name,
    price: product.price,
    stock: product.stock,
    imageUrl: product.imageUrls.isEmpty ? null : product.imageUrls.first,
    category: product.category,
  );

  static const freshFlowers = Category(
    id: '20000000-0000-4000-8000-000000000001',
    name: 'Hoa tươi',
    slug: 'hoa-tuoi',
  );
  static const plants = Category(
    id: '20000000-0000-4000-8000-000000000002',
    name: 'Cây cảnh',
    slug: 'cay-canh',
  );
  static const accessories = Category(
    id: '20000000-0000-4000-8000-000000000003',
    name: 'Phụ kiện',
    slug: 'phu-kien',
  );

  static const defaultCategories = [freshFlowers, plants, accessories];

  /// Xếp theo "mới nhất" trước.
  static const defaultProducts = [
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000001',
      sku: 'FL-092',
      name: 'Bó Hoa Bạch Hồng Étoile & Greenery',
      description:
          'Bạch hồng Ecuador cao cấp phối cùng cành lá khuynh diệp và hoa phụ '
          'mộc mạc, tôn vinh vẻ đẹp thuần khiết và thanh lịch trong từng '
          'đường nét tự nhiên.',
      price: 490000,
      stock: 12,
      taxRate: 8,
      category: freshFlowers,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000002',
      sku: 'PL-104',
      name: 'Cây Bàng Singapore Mini',
      description:
          'Dáng cây gọn, lá to xanh bóng, hợp đặt bàn làm việc hoặc góc '
          'phòng khách có ánh sáng gián tiếp.',
      price: 350000,
      stock: 8,
      taxRate: 8,
      category: plants,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000003',
      sku: 'AC-018',
      name: 'Bình Gốm Men Mộc Muted',
      description: 'Bình gốm thủ công men mộc, tông màu trung tính.',
      price: 280000,
      stock: 20,
      taxRate: 10,
      category: accessories,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000004',
      sku: 'FL-115',
      name: 'Bó Tulip Hà Lan Trắng',
      description: 'Tulip trắng nhập khẩu Hà Lan, gói giấy kraft mộc mạc.',
      price: 620000,
      stock: 5,
      taxRate: 8,
      category: freshFlowers,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000005',
      sku: 'PL-087',
      name: 'Cây Lưỡi Hổ Viền Vàng',
      description: 'Cây lọc không khí, dễ chăm, chịu bóng tốt.',
      price: 290000,
      stock: 15,
      taxRate: 8,
      category: plants,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000006',
      sku: 'FL-120',
      name: 'Bó Hoa Cúc Họa Mi Thuần Khiết',
      description: 'Cúc họa mi Hà Nội đầu mùa, bó tròn nhỏ xinh.',
      price: 380000,
      stock: 10,
      taxRate: 8,
      category: freshFlowers,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000007',
      sku: 'PL-112',
      name: 'Cây Trầu Bà Thanh Xuân',
      description: 'Lá xẻ thùy lớn, mang không khí nhiệt đới vào nhà.',
      price: 420000,
      stock: 6,
      taxRate: 8,
      category: plants,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000008',
      sku: 'AC-024',
      name: 'Bình Thủy Tinh Khói Cổ Điển',
      description: 'Bình thủy tinh màu khói, hợp cắm cành dài.',
      price: 195000,
      stock: 25,
      taxRate: 10,
      category: accessories,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000009',
      sku: 'FL-131',
      name: 'Bó Cẩm Tú Cầu Xanh Mộng',
      description: 'Cẩm tú cầu Đà Lạt xanh dịu, gói voan trắng.',
      price: 550000,
      stock: 0,
      taxRate: 8,
      category: freshFlowers,
    ),
    ProductDetail(
      id: '30000000-0000-4000-8000-000000000010',
      sku: 'AC-031',
      name: 'Kéo Cắt Cành Chuyên Dụng',
      description: 'Thép không gỉ, lò xo trợ lực, cắt gọn cành hoa và cây.',
      price: 160000,
      stock: 30,
      taxRate: 10,
      category: accessories,
    ),
  ];
}
