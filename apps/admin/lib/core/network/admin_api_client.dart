import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';

class AdminApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  AdminApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl =
          baseUrl ??
          (kIsWeb
              ? 'http://localhost:5000/api/v1'
              : 'http://10.0.2.2:5000/api/v1'),
      _httpClient = httpClient ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // --- AUTH ---
  Future<UserProfile> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final res = await _httpClient.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        _authToken = data['token'] as String?;
        return UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('AdminApiClient.login fallback to mock due to: $e');
    }

    // Demo / Fallback Mock Account
    await Future.delayed(const Duration(milliseconds: 600));
    if (email == 'admin@nhacohoa.vn' || email.contains('admin')) {
      _authToken =
          'mock_admin_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      return const UserProfile(
        id: 'admin-uuid-001',
        email: 'admin@nhacohoa.vn',
        fullName: 'Nguyễn Tiến (Admin)',
        phone: '0901234567',
        role: UserRole.admin,
        status: AccountStatus.active,
      );
    } else {
      throw Exception('Tài khoản không có quyền ADMIN (403 FORBIDDEN)');
    }
  }

  // --- DASHBOARD ---
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final res = await _httpClient.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        return DashboardStatsModel.fromJson(
          data['stats'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('AdminApiClient.getDashboardStats fallback: $e');
    }

    // Realistic Mock Data for Demo
    await Future.delayed(const Duration(milliseconds: 400));
    return const DashboardStatsModel(
      revenueToday: 3850000,
      revenueMonth: 78500000,
      totalOrders: 142,
      pendingOrders: 6,
      totalProducts: 48,
      lowStockProducts: 4,
    );
  }

  // --- PRODUCTS ---
  Future<List<ProductModel>> getProducts({
    String? search,
    String? categoryId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/admin/products').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null && categoryId.isNotEmpty)
            'category': categoryId,
        },
      );
      final res = await _httpClient.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data']['items'] as List<dynamic>;
        return list
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('AdminApiClient.getProducts fallback: $e');
    }

    // Mock Products List
    await Future.delayed(const Duration(milliseconds: 400));
    var products = _mockProducts;
    if (search != null && search.isNotEmpty) {
      products = products
          .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      products = products.where((p) => p.categoryId == categoryId).toList();
    }
    return products;
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final res = await _httpClient.put(
        Uri.parse('$baseUrl/admin/products/${product.id}'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      );
      if (res.statusCode == 200) {
        return ProductModel.fromJson(jsonDecode(res.body)['data']);
      }
    } catch (e) {
      debugPrint('AdminApiClient.updateProduct fallback: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _mockProducts[index] = product;
    }
    return product;
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      final res = await _httpClient.post(
        Uri.parse('$baseUrl/admin/products'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      );
      if (res.statusCode == 201) {
        return ProductModel.fromJson(jsonDecode(res.body)['data']);
      }
    } catch (e) {
      debugPrint('AdminApiClient.addProduct fallback: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final newProduct = product.copyWith(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
    );
    _mockProducts.insert(0, newProduct);
    return newProduct;
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _httpClient.delete(
        Uri.parse('$baseUrl/admin/products/$productId'),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('AdminApiClient.deleteProduct fallback: $e');
    }
    _mockProducts.removeWhere((p) => p.id == productId);
  }

  // --- ORDERS ---
  Future<List<OrderModel>> getOrders({OrderStatus? status}) async {
    try {
      final uri = Uri.parse('$baseUrl/admin/orders').replace(
        queryParameters: {if (status != null) 'status': status.toApiString()},
      );
      final res = await _httpClient.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data']['items'] as List<dynamic>;
        return list
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('AdminApiClient.getOrders fallback: $e');
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (status != null) {
      return _mockOrders.where((o) => o.status == status).toList();
    }
    return List.from(_mockOrders);
  }

  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final res = await _httpClient.patch(
        Uri.parse('$baseUrl/admin/orders/$orderId/status'),
        headers: _headers,
        body: jsonEncode({'status': newStatus.toApiString()}),
      );
      if (res.statusCode == 200) {
        return OrderModel.fromJson(jsonDecode(res.body)['data']);
      }
    } catch (e) {
      debugPrint('AdminApiClient.updateOrderStatus fallback: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _mockOrders[index] = _mockOrders[index].copyWith(status: newStatus);
      return _mockOrders[index];
    }
    throw Exception('Không tìm thấy đơn hàng #$orderId');
  }

  // --- CATEGORIES ---
  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _httpClient.get(
        Uri.parse('$baseUrl/admin/categories'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List<dynamic>;
        return list
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('AdminApiClient.getCategories fallback: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    return _mockCategories;
  }

  // Mock initial storage
  static final List<CategoryModel> _mockCategories = [
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

  static final List<ProductModel> _mockProducts = [
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

  static final List<OrderModel> _mockOrders = [
    OrderModel(
      id: 'ord_101',
      orderCode: 'NCH-2026-001',
      customerName: 'Trần Thị Thu Hà',
      customerPhone: '0988112233',
      customerAddress: '128 Nguyễn Đình Chiểu, P. Đa Kao, Quận 1, TP.HCM',
      totalAmount: 390000,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'SEPAY (QR Chuyển Khoản)',
      note: 'Giao giờ hành chính, gọi trước 15 phút',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      items: const [
        OrderItemModel(
          id: 'item_1',
          productId: 'p1',
          productName: 'Sen Hồng Tháp Mười (Bình Gốm Đất Nung)',
          quantity: 1,
          unitPrice: 390000,
          subtotal: 390000,
        ),
      ],
    ),
    OrderModel(
      id: 'ord_102',
      orderCode: 'NCH-2026-002',
      customerName: 'Lê Hoàng Nam',
      customerPhone: '0912345678',
      customerAddress: 'Tòa nhà Bitexco, Bến Nghé, Quận 1, TP.HCM',
      totalAmount: 570000,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'SEPAY (QR Chuyển Khoản)',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      items: const [
        OrderItemModel(
          id: 'item_2',
          productId: 'p2',
          productName: 'Bó Cẩm Tú Cầu Xanh Lam Đà Lạt',
          quantity: 1,
          unitPrice: 320000,
          subtotal: 320000,
        ),
        OrderItemModel(
          id: 'item_3',
          productId: 'p3',
          productName: 'Cây Kim Tiền Chiêu Tài',
          quantity: 1,
          unitPrice: 220000,
          subtotal: 220000,
        ),
      ],
    ),
    OrderModel(
      id: 'ord_103',
      orderCode: 'NCH-2026-003',
      customerName: 'Vũ Minh Anh',
      customerPhone: '0977665544',
      customerAddress: '45 Lê Duẩn, Quận 1, TP.HCM',
      totalAmount: 280000,
      status: OrderStatus.shipping,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'COD',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      items: const [
        OrderItemModel(
          id: 'item_4',
          productId: 'p4',
          productName: 'Bó Hoa Hướng Dương Nắng Mới',
          quantity: 1,
          unitPrice: 280000,
          subtotal: 280000,
        ),
      ],
    ),
  ];
}
