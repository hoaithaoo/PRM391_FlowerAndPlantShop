import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AdministrativeUnit {
  const AdministrativeUnit({required this.code, required this.name});

  final int code;
  final String name;

  factory AdministrativeUnit.fromJson(Map<String, dynamic> json) {
    final rawCode = json['code'];
    final code = rawCode is num ? rawCode.toInt() : int.tryParse('$rawCode');
    final name = json['name']?.toString().trim() ?? '';
    if (code == null || name.isEmpty) {
      throw const FormatException('Đơn vị hành chính không hợp lệ.');
    }
    return AdministrativeUnit(code: code, name: name);
  }
}

class AdministrativeLocationException implements Exception {
  const AdministrativeLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VietnamAdministrativeService {
  VietnamAdministrativeService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    Uri? baseUri,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _baseUri = baseUri ?? Uri.parse('https://provinces.open-api.vn/api/v1/');

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final Uri _baseUri;

  Future<List<AdministrativeUnit>> listProvinces() async {
    final json = await _getJson(_baseUri.resolve('p/'));
    return _parseUnits(json);
  }

  Future<List<AdministrativeUnit>> listDistricts(int provinceCode) async {
    final json = await _getJson(_baseUri.resolve('p/$provinceCode?depth=2'));
    if (json is! Map<String, dynamic>) {
      throw const AdministrativeLocationException(
        'Dữ liệu quận/huyện không hợp lệ.',
      );
    }
    return _parseUnits(json['districts']);
  }

  Future<List<AdministrativeUnit>> listWards(int districtCode) async {
    final json = await _getJson(_baseUri.resolve('d/$districtCode?depth=2'));
    if (json is! Map<String, dynamic>) {
      throw const AdministrativeLocationException(
        'Dữ liệu phường/xã không hợp lệ.',
      );
    }
    return _parseUnits(json['wards']);
  }

  Future<dynamic> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(
            uri,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw const AdministrativeLocationException(
          'Không thể tải dữ liệu địa chỉ. Vui lòng thử lại.',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on AdministrativeLocationException {
      rethrow;
    } on TimeoutException {
      throw const AdministrativeLocationException(
        'Tải dữ liệu địa chỉ quá thời gian. Vui lòng thử lại.',
      );
    } on Object {
      throw const AdministrativeLocationException(
        'Không thể tải dữ liệu địa chỉ. Vui lòng kiểm tra kết nối mạng.',
      );
    }
  }

  List<AdministrativeUnit> _parseUnits(dynamic json) {
    if (json is! List) {
      throw const AdministrativeLocationException(
        'Dữ liệu địa chỉ không đúng định dạng.',
      );
    }
    try {
      return json
          .map(
            (item) => AdministrativeUnit.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on Object {
      throw const AdministrativeLocationException(
        'Dữ liệu địa chỉ không đúng định dạng.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
