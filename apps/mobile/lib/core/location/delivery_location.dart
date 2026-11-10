import 'location_service.dart';

/// Địa chỉ và tọa độ của cùng một ghim đã được người dùng xác nhận.
class DeliveryLocation {
  const DeliveryLocation({required this.coordinates, required this.address});

  final LocationCoordinates coordinates;
  final String address;
}
