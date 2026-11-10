import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

import 'location_service.dart';

typedef PlacemarkLookup = Future<List<Placemark>> Function(
  double latitude,
  double longitude,
);

class AddressLookupException implements Exception {
  const AddressLookupException();

  String get message =>
      'Không tìm được địa chỉ từ vị trí này. Bạn có thể thử lại hoặc nhập địa chỉ bên dưới.';
}

/// Lấy vị trí theo quyền của thiết bị, rồi dùng geocoder của hệ điều hành.
/// Không khởi tạo plugin hay xin quyền cho đến khi người dùng bấm nút.
class CurrentAddressService {
  const CurrentAddressService({
    this.locationService = const LocationService(),
    this.lookup,
    this.lookupTimeout = const Duration(seconds: 10),
  });

  final LocationService locationService;
  final PlacemarkLookup? lookup;
  final Duration lookupTimeout;

  bool get supportsSettings => locationService.supportsSettings;

  Future<LocationCoordinates> getCurrentCoordinates() async {
    final coordinates = await locationService.getCurrentCoordinates();
    if (!coordinates.isValid) {
      throw const LocationException(LocationFailure.invalidCoordinates);
    }
    return coordinates;
  }

  Future<String> getCurrentAddress() async =>
      getAddressForCoordinates(await getCurrentCoordinates());

  Future<String> getAddressForCoordinates(
      LocationCoordinates coordinates) async {
    if (!coordinates.isValid) {
      throw const LocationException(LocationFailure.invalidCoordinates);
    }
    try {
      final resolve = lookup ?? _lookup;
      final placemarks = await resolve(
        coordinates.latitude,
        coordinates.longitude,
      ).timeout(lookupTimeout);
      for (final placemark in placemarks) {
        final address = formatAddress(placemark);
        if (address.isNotEmpty) return address;
      }
    } catch (_) {
      throw const AddressLookupException();
    }
    throw const AddressLookupException();
  }

  Future<List<Placemark>> _lookup(double latitude, double longitude) {
    if (kIsWeb) throw const AddressLookupException();
    return Geocoding(locale: const Locale('vi', 'VN'))
        .placemarkFromCoordinates(latitude, longitude);
  }

  Future<bool> openAppSettings() => locationService.openAppSettings();

  Future<bool> openLocationSettings() => locationService.openLocationSettings();

  @visibleForTesting
  static String formatAddress(Placemark placemark) {
    final street = placemark.street?.trim();
    final streetParts = [placemark.subThoroughfare, placemark.thoroughfare]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    final streetAddress =
        street == null || street.isEmpty ? streetParts : street;
    // Chỉ tên tỉnh/quốc gia không đủ làm địa chỉ giao hàng.
    if (streetAddress.isEmpty) return '';
    final seen = <String>{};
    return [
      streetAddress,
      placemark.subLocality,
      placemark.subAdministrativeArea,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ]
        .whereType<String>()
        .expand((part) => part.split(','))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && seen.add(part.toLowerCase()))
        .join(', ');
  }
}
