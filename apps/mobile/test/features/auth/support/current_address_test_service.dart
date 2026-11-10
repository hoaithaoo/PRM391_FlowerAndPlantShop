import 'package:plant_flower_mobile/core/location/current_address_service.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';

class TestCurrentAddressService extends CurrentAddressService {
  Future<String> Function()? resolve;
  Future<LocationCoordinates> Function()? locate;
  Future<String> Function(LocationCoordinates)? reverse;
  int coordinateCalls = 0;
  final lookups = <LocationCoordinates>[];
  int calls = 0;
  int appSettingsCalls = 0;
  int locationSettingsCalls = 0;

  @override
  bool get supportsSettings => true;

  @override
  Future<LocationCoordinates> getCurrentCoordinates() async {
    coordinateCalls++;
    return await locate?.call() ??
        const LocationCoordinates(
          latitude: 10.77,
          longitude: 106.69,
          accuracy: 20,
        );
  }

  @override
  Future<String> getAddressForCoordinates(LocationCoordinates point) async {
    lookups.add(point);
    if (reverse != null) {
      calls++;
      return reverse!(point);
    }
    return getCurrentAddress();
  }

  @override
  Future<String> getCurrentAddress() async {
    calls++;
    return await resolve?.call() ?? '123 Đường Hoa, Phường 1, TP. Hồ Chí Minh';
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsCalls++;
    return true;
  }
}
