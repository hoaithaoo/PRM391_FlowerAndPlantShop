import 'package:geolocator/geolocator.dart';
import 'dart:async';

// trạng thái thất bại khi lấy vị trí
enum LocationFailure { serviceDisabled, denied, deniedForever, timeout }

class LocationException implements Exception {
  const LocationException(this.failure);
  final LocationFailure failure;
}

class LocationService {
  const LocationService();
  // hàm getCurrentLocation trả về một Future<Position> để xác định xem vị trí hiện tại có được lấy thành công hay không.
  Future<Position> getCurrentLocation() async {
    // dùng await để chờ kết quả của các hàm bất đồng bộ
    //! await Geolocator.isLocationServiceEnabled() kiểm tra xem dịch vụ định vị có được bật hay không. Nếu không, ném ra LocationException với LocationFailure.serviceDisabled.
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    // dùng denied để xác định xem quyền truy cập vị trí
    // always và whileInUse là quyền truy cập vị trí được phép, trong khi denied và deniedForever là quyền truy cập vị trí bị từ chối.

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationFailure.denied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    // lấy toạ độ
    try {
      // 2. Sửa chữ 'Try' thành 'try' viết thường
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw const LocationException(LocationFailure.timeout);
    } // 3. Đã xóa dấu ngoặc nhọn '}' bị thừa ở đây
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
