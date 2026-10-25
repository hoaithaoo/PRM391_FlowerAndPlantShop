import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'api_exceptions.dart';
import '../services/contracts/admin_auth_service.dart';
import '../services/contracts/admin_dashboard_service.dart';
import '../services/contracts/admin_products_service.dart';
import '../services/contracts/admin_categories_service.dart';
import '../services/contracts/admin_orders_service.dart';
import '../services/contracts/admin_users_service.dart';
import '../services/contracts/admin_finance_service.dart';
import '../mock/clusters/mock_auth_service.dart';
import '../mock/clusters/mock_dashboard_service.dart';
import '../mock/clusters/mock_products_service.dart';
import '../mock/clusters/mock_categories_service.dart';
import '../mock/clusters/mock_orders_service.dart';
import '../mock/clusters/mock_users_service.dart';
import '../mock/clusters/mock_finance_service.dart';
import '../remote/clusters/remote_auth_service.dart';
import '../remote/clusters/remote_dashboard_service.dart';
import '../remote/clusters/remote_products_service.dart';
import '../remote/clusters/remote_categories_service.dart';
import '../remote/clusters/remote_orders_service.dart';
import '../remote/clusters/remote_users_service.dart';
import '../remote/clusters/remote_finance_service.dart';

export 'api_exceptions.dart';
export '../services/contracts/admin_auth_service.dart';
export '../services/contracts/admin_dashboard_service.dart';
export '../services/contracts/admin_products_service.dart';
export '../services/contracts/admin_categories_service.dart';
export '../services/contracts/admin_orders_service.dart';
export '../services/contracts/admin_users_service.dart';
export '../services/contracts/admin_finance_service.dart';
export '../remote/clusters/remote_auth_service.dart';
export '../remote/clusters/remote_dashboard_service.dart';
export '../remote/clusters/remote_products_service.dart';
export '../remote/clusters/remote_categories_service.dart';
export '../remote/clusters/remote_orders_service.dart';
export '../remote/clusters/remote_users_service.dart';
export '../remote/clusters/remote_finance_service.dart';

class AdminApiClient {
  final String baseUrl;
  final http.Client httpClient;
  String? _authToken;
  VoidCallback? onSessionExpired;

  // 7 Cụm nghiệp vụ độc lập (Có thể thay thế / cắm API thật từng cụm)
  late AdminAuthService auth;
  late AdminDashboardService dashboard;
  late AdminProductsService products;
  late AdminCategoriesService categories;
  late AdminOrdersService orders;
  late AdminUsersService users;
  late AdminFinanceService finance;

  AdminApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.onSessionExpired,
    AdminAuthService? auth,
    AdminDashboardService? dashboard,
    AdminProductsService? products,
    AdminCategoriesService? categories,
    AdminOrdersService? orders,
    AdminUsersService? users,
    AdminFinanceService? finance,
  })  : baseUrl = baseUrl ??
            (kIsWeb
                ? 'http://localhost:5000/api/v1'
                : 'http://10.0.2.2:5000/api/v1'),
        httpClient = httpClient ?? http.Client() {
    this.auth = auth ?? MockAuthService(onTokenGenerated: setAuthToken);
    this.dashboard = dashboard ?? MockDashboardService();
    this.products = products ?? MockProductsService();
    this.categories = categories ?? MockCategoriesService();
    this.orders = orders ?? MockOrdersService();
    this.users = users ?? MockUsersService();
    this.finance = finance ?? MockFinanceService();
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  void handleResponseStatus(http.Response res) {
    if (res.statusCode >= 400) {
      final err = parseApiResponseError(res.statusCode, res.body);
      if (err is AuthTokenInvalidException || err is AuthTokenMissingException) {
        _authToken = null;
        onSessionExpired?.call();
      }
      throw err;
    }
  }

  // --- CÁC HÀM TẠO REMOTE SERVICE (KHI CẦN GẮN BACKEND THẬT) ---
  RemoteAuthService createRemoteAuth() => RemoteAuthService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
        onTokenSaved: setAuthToken,
      );

  RemoteDashboardService createRemoteDashboard() => RemoteDashboardService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
      );

  RemoteProductsService createRemoteProducts() => RemoteProductsService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
      );

  RemoteCategoriesService createRemoteCategories() => RemoteCategoriesService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
      );

  RemoteOrdersService createRemoteOrders() => RemoteOrdersService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
      );

  RemoteUsersService createRemoteUsers() => RemoteUsersService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
      );

  RemoteFinanceService createRemoteFinance() => RemoteFinanceService(
        httpClient: httpClient,
        baseUrl: baseUrl,
        headersProvider: () => headers,
        responseValidator: handleResponseStatus,
      );

  // --- 1. AUTH ---
  Future<UserProfile> loginWithEmailPassword(String email, String password) =>
      auth.loginWithEmailPassword(email, password);

  // --- 2. DASHBOARD ---
  Future<DashboardStatsModel> getDashboardStats({DateTime? from, DateTime? to}) =>
      dashboard.getDashboardStats(from: from, to: to);

  // --- 3. PRODUCTS ---
  Future<List<ProductModel>> getProducts({String? categoryId, String? search}) =>
      products.getProducts(categoryId: categoryId, search: search);

  Future<ProductModel> addProduct(ProductModel product) =>
      products.addProduct(product);

  Future<ProductModel> updateProduct(ProductModel product) =>
      products.updateProduct(product);

  Future<void> deleteProduct(String id) => products.deleteProduct(id);

  // --- 4. CATEGORIES ---
  Future<List<CategoryModel>> getCategories() => categories.getCategories();

  Future<CategoryModel> addCategory(CategoryModel category) =>
      categories.addCategory(category);

  Future<CategoryModel> updateCategory(CategoryModel category) =>
      categories.updateCategory(category);

  Future<void> deleteCategory(String id) => categories.deleteCategory(id);

  // --- 5. ORDERS ---
  Future<List<OrderModel>> getOrders({OrderStatus? status, String? search}) =>
      orders.getOrders(status: status, search: search);

  Future<OrderModel> updateOrderStatus(String id, OrderStatus newStatus) =>
      orders.updateOrderStatus(id, newStatus);

  // --- 6. USERS ---
  Future<List<UserProfile>> getUsers({
    String? search,
    UserRole? role,
    AccountStatus? status,
    int page = 1,
  }) =>
      users.getUsers(search: search, role: role, status: status, page: page);

  Future<UserProfile> getUserDetail(String id) => users.getUserDetail(id);

  Future<UserProfile> updateUser(
    String id, {
    UserRole? role,
    AccountStatus? status,
  }) =>
      users.updateUser(id, role: role, status: status);

  // --- 7. FINANCE (INVOICES & SEPAY) ---
  Future<List<InvoiceModel>> getInvoices({
    InvoiceStatus? status,
    String? search,
    int page = 1,
  }) =>
      finance.getInvoices(status: status, search: search, page: page);

  Future<InvoiceModel> getInvoiceDetail(String id) =>
      finance.getInvoiceDetail(id);

  Future<List<SepayTransactionModel>> getSepayTransactions({
    bool? isMatched,
    String? search,
    int page = 1,
  }) =>
      finance.getSepayTransactions(
        isMatched: isMatched,
        search: search,
        page: page,
      );

  Future<SepayTransactionModel> manualMatchTransaction({
    required String transactionId,
    required String orderCode,
  }) =>
      finance.manualMatchTransaction(
        transactionId: transactionId,
        orderCode: orderCode,
      );
}
