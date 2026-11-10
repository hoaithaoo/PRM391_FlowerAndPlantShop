import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Toạ độ của một địa chỉ.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Đổi địa chỉ dạng chữ thành toạ độ. Trả về null khi không tìm được, không
/// bao giờ ném lỗi: đăng ký vẫn tiếp tục với lat/lng rỗng.
abstract interface class AddressGeocoder {
  Future<GeoPoint?> geocode(String address);
}

/// Geocode bằng Nominatim của OpenStreetMap (docs/spec.md: map dùng OSM).
///
/// Chính sách dùng Nominatim: tối đa 1 request/giây và phải có User-Agent
/// riêng (https://operations.osmfoundation.org/policies/nominatim/).
class NominatimAddressGeocoder implements AddressGeocoder {
  NominatimAddressGeocoder({
    http.Client? client,
    this.timeout = const Duration(seconds: 4),
    this.retryDelay = const Duration(milliseconds: 1100),
  }) : _client = client ?? http.Client();

  static const _userAgent = 'NhaCoHoa-FlowerAndPlantShop/1.0 (Flutter)';

  final http.Client _client;
  final Duration timeout;

  /// Khoảng chờ trước lần thử lại để không vượt 1 request/giây.
  final Duration retryDelay;

  @override
  Future<GeoPoint?> geocode(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    final point = await _search(query);
    if (point != null) return point;

    // Địa chỉ hẻm kiểu "44/16/44, Phạm Văn Chiêu, ..." thường không có trong
    // OSM: bỏ phần số nhà để lấy toạ độ theo tên đường.
    final fallback = withoutHouseNumber(query);
    if (fallback == null) return null;
    await Future<void>.delayed(retryDelay);
    return _search(fallback);
  }

  /// Bỏ đoạn đầu (số nhà) của địa chỉ có dấu phẩy. Trả về null nếu không còn
  /// đủ thông tin để tìm.
  @visibleForTesting
  static String? withoutHouseNumber(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 3) return null;
    return parts.skip(1).join(', ');
  }

  Future<GeoPoint?> _search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'vn',
      'accept-language': 'vi',
    });
    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(timeout);
      if (response.statusCode != 200) {
        debugPrint('[Geocode] Nominatim trả về ${response.statusCode}');
        return null;
      }
      final results = jsonDecode(response.body);
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      if (first is! Map) return null;
      final lat = double.tryParse('${first['lat']}');
      final lon = double.tryParse('${first['lon']}');
      if (lat == null || lon == null) return null;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
      return GeoPoint(lat, lon);
    } catch (error) {
      // Mất mạng, timeout, JSON hỏng: bỏ qua, lat/lng để null
      debugPrint('[Geocode] Lỗi khi tìm toạ độ: $error');
      return null;
    }
  }
}
