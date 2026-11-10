import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_reviews_service.dart';

/// Gọi API thật /admin/reviews: danh sách đánh giá (20 bài/trang) và ẩn/hiện đánh giá.
class RemoteReviewsService implements AdminReviewsService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteReviewsService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<AdminReviewList> getReviews({
    int? rating,
    bool? hidden,
    String? search,
    int page = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/reviews').replace(
      queryParameters: <String, String>{
        'page': '$page',
        'limit': '20',
        if (rating != null) 'rating': '$rating',
        if (hidden != null) 'hidden': '$hidden',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    // meta gồm phân trang + điểm trung bình/số bài đang hiện (tính trên toàn bộ, không theo bộ lọc).
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    final items = (body['data']['items'] as List<dynamic>)
        .map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdminReviewList(
      items: items,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      averageRating: (meta['averageRating'] as num?)?.toDouble() ?? 0,
      visibleReviews: (meta['visibleReviews'] as num?)?.toInt() ?? 0,
      page: (meta['page'] as num?)?.toInt() ?? page,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? page,
    );
  }

  @override
  Future<ProductReview> setReviewHidden(String id, bool isHidden) async {
    final res = await httpClient.patch(
      Uri.parse('$baseUrl/admin/reviews/${Uri.encodeComponent(id)}'),
      headers: headersProvider(),
      body: jsonEncode({'isHidden': isHidden}),
    );
    responseValidator?.call(res);
    return ProductReview.fromJson(
      jsonDecode(res.body)['data'] as Map<String, dynamic>,
    );
  }
}
